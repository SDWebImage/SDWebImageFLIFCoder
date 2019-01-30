//
//  SDImageFLIFCoder.m
//  SDWebImageFLIFCoder
//
//  Created by lizhuoli on 2019/1/30.
//

#import "SDImageFLIFCoder.h"
#if __has_include(<libflif/flif.h>)
#import <libflif/flif.h>
#else
#import "flif.h"
#endif

#define SD_FOUR_CC(c1,c2,c3,c4) ((uint32_t)(((c4) << 24) | ((c3) << 16) | ((c2) << 8) | (c1)))

static void FreeImageData(void *info, const void *data, size_t size) {
    free((void *)data);
}

@implementation SDImageFLIFCoder

+ (SDImageFLIFCoder *)sharedCoder {
    static SDImageFLIFCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[SDImageFLIFCoder alloc] init];
    });
    return coder;
}

#pragma mark - Decode

- (BOOL)canDecodeFromData:(NSData *)data {
    return [[self class] isFLIFFormatForData:data];
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(SDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    
    BOOL decodeFirstFrame = [options[SDImageCoderDecodeFirstFrameOnly] boolValue];
    CGFloat scale = 1;
    NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
    if (scaleFactor != nil) {
        scale = [scaleFactor doubleValue];
        if (scale < 1) {
            scale = 1;
        }
    }
    
    FLIF_DECODER *decoder = flif_create_decoder();
    if (!decoder) {
        return nil;
    }
    
    int result = flif_decoder_decode_memory(decoder, [data bytes], [data length]);
    if (!result) {
        return nil;
    }
    
    // returns the number of frames (1 if it is not an animation)
    size_t frameCount = flif_decoder_num_images(decoder);
    int32_t loopCount = flif_decoder_num_loops(decoder);
    
    if (decodeFirstFrame || frameCount <= 1) {
        // static FLIF image
        FLIF_IMAGE *flifimage = flif_decoder_get_image(decoder, 0);
        CGImageRef imageRef = [self sd_createFrameWithFLIFImage:flifimage];
        if (!imageRef) {
            flif_destroy_decoder(decoder);
            return nil;
        }
#if SD_UIKIT || SD_WATCH
        UIImage *staticImage = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
#else
        UIImage *staticImage = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:kCGImagePropertyOrientationUp];
#endif
        staticImage.sd_imageFormat = SDImageFormatFLIF;
        CGImageRelease(imageRef);
        flif_destroy_decoder(decoder);
        return staticImage;
    }
    
    // animated FLIF image
    NSMutableArray<SDImageFrame *> *frames = [NSMutableArray array];
    
    for (size_t i = 0; i < frameCount; i++) {
        @autoreleasepool {
            FLIF_IMAGE *flifimage = flif_decoder_get_image(decoder, i);
            CGImageRef imageRef = [self sd_createFrameWithFLIFImage:flifimage];
            if (!imageRef) {
                continue;
            }
#if SD_UIKIT || SD_WATCH
            UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
#else
            UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:kCGImagePropertyOrientationUp];
#endif
            CGImageRelease(imageRef);
            // libflif duration is milliseconds
            NSTimeInterval duration = [self sd_frameDurationWithFLIFImage:flifimage];
            SDImageFrame *frame = [SDImageFrame frameWithImage:image duration:duration];
            [frames addObject:frame];
        }
    }
    
    flif_destroy_decoder(decoder);
    
    UIImage *animatedImage = [SDImageCoderHelper animatedImageWithFrames:frames];
    animatedImage.sd_imageLoopCount = loopCount;
    animatedImage.sd_imageFormat = SDImageFormatFLIF;
    
    return animatedImage;
}

- (nullable CGImageRef)sd_createFrameWithFLIFImage:(nullable FLIF_IMAGE *)flifimage {
    if (!flifimage) {
        return nil;
    }
    
    // Get image info
    size_t channels = flif_image_get_nb_channels(flifimage);
    BOOL hasAlpha = (channels > 3);
    size_t width = flif_image_get_width(flifimage);
    size_t height = flif_image_get_height(flifimage);
    
    // use RGBA 4 channels
    size_t bytesPerRow = width * 4;
    size_t bytesLength = height * bytesPerRow;
    
    // allocate buffer
    char *buf = calloc(bytesLength, 1);
    if (!buf) {
        return nil;
    }
    char *idx = (char *)buf;
    
    // read all rows into buffer
    for (int y = 0; y < height; y++)
    {
        flif_image_read_row_RGBA8(flifimage, y, idx, bytesPerRow);
        idx += bytesPerRow;
    }
    
    // Construct a UIImage from the decoded bitmapbuffer
    size_t bitsPerPixel = 32;
    size_t bitsPerComponent = 8;
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big;
    bitmapInfo |= hasAlpha ? kCGImageAlphaLast : kCGImageAlphaNoneSkipLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGDataProviderRef provider =
    CGDataProviderCreateWithData(NULL, buf, bytesLength, FreeImageData);
    CGColorSpaceRef colorSpaceRef = [SDImageCoderHelper colorSpaceGetDeviceRGB];
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    CGDataProviderRelease(provider);
    
    return imageRef;
}

- (NSTimeInterval)sd_frameDurationWithFLIFImage:(FLIF_IMAGE *)flifimage {
    int duration = flif_image_get_frame_delay(flifimage);
    if (duration <= 10) {
        duration = 100;
    }
    return duration / 1000.0;
}

#pragma mark - Progressive Decode

- (BOOL)canIncrementalDecodeFromData:(NSData *)data {
    return [[self class] isFLIFFormatForData:data];
}

- (instancetype)initIncrementalWithOptions:(SDImageCoderOptions *)options {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)updateIncrementalData:(NSData *)data finished:(BOOL)finished {
    ;
}

- (UIImage *)incrementalDecodedImageWithOptions:(SDImageCoderOptions *)options {
    return nil;
}

#pragma mark - Encode

- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    if (format == SDImageFormatFLIF) {
        return YES;
    }
    return NO;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(SDImageCoderOptions *)options {
    return nil;
}

#pragma mark - Helper

+ (BOOL)isFLIFFormatForData:(NSData *)data {
    if (!data) {
        return NO;
    }
    uint32_t magic4;
    [data getBytes:&magic4 length:4]; // 4 Bytes Magic Code for most file format.
    switch (magic4) {
        case SD_FOUR_CC('F', 'L', 'I', 'F'): { // FLIF
            return YES;
        }
        default: {
            return NO;
        }
    }
}

@end
