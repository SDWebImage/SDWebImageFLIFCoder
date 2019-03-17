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
#import <Accelerate/Accelerate.h>
#include <dlfcn.h>

#define SD_FOUR_CC(c1,c2,c3,c4) ((uint32_t)(((c4) << 24) | ((c3) << 16) | ((c2) << 8) | (c1)))

static void FreeImageData(void *info, const void *data, size_t size) {
    free((void *)data);
}

@implementation SDImageFLIFCoder {
    FLIF_DECODER * _decoder;
    FLIF_INFO * _flifinfo;
    NSData *_imageData;
    CGFloat _scale;
    BOOL _finished;
}

- (void)dealloc {
    if (_decoder) {
        flif_destroy_decoder(_decoder);
        _decoder = NULL;
    }
    if (_flifinfo) {
        flif_destroy_info(_flifinfo);
        _flifinfo = NULL;
    }
}

+ (SDImageFLIFCoder *)sharedCoder {
    static SDImageFLIFCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[SDImageFLIFCoder alloc] init];
    });
    return coder;
}

#if DEBUG
// This is used to disable libflif's verbose output during DEBUG (verbose = 10)
+ (void)initialize {
    void (*increase_verbosity)(int) = dlsym(RTLD_SELF, "_Z18increase_verbosityi");
    if (increase_verbosity) {
        increase_verbosity(1 - 10);
    }
}
#endif

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
        flif_destroy_decoder(decoder);
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
            // libflif frame duration is milliseconds
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
        _decoder = flif_create_decoder();
        CGFloat scale = 1;
        NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = [scaleFactor doubleValue];
            if (scale < 1) {
                scale = 1;
            }
        }
        _scale = scale;
    }
    return self;
}

- (void)updateIncrementalData:(NSData *)data finished:(BOOL)finished {
    if (_finished) {
        return;
    }
    _imageData = data;
    _finished = finished;
    if (!_flifinfo) {
        _flifinfo = flif_read_info_from_memory(data.bytes, data.length);
    }
}

- (UIImage *)incrementalDecodedImageWithOptions:(SDImageCoderOptions *)options {
    if (!_flifinfo) {
        return nil;
    }
    size_t frameCount = flif_info_num_images(_flifinfo);
    // supports only static FLIF progressive decoding
    if (frameCount != 1) {
        return nil;
    }
    int result = flif_decoder_decode_memory(_decoder, _imageData.bytes, _imageData.length);
    if (!result) {
        return nil;
    }    
    FLIF_IMAGE *flifimage = flif_decoder_get_image(_decoder, 0);
    if (!flifimage) {
        return nil;
    }
    
    CGImageRef imageRef = [self sd_createFrameWithFLIFImage:flifimage];
    if (!imageRef) {
        return nil;
    }
    
    CGFloat scale = _scale;
#if SD_UIKIT || SD_WATCH
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
#else
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:kCGImagePropertyOrientationUp];
#endif
    CGImageRelease(imageRef);
    
    return image;
}

#pragma mark - Encode

- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    if (format == SDImageFormatFLIF) {
        return YES;
    }
    return NO;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(SDImageCoderOptions *)options {
    if (!image) {
        return nil;
    }
    double compressionQuality = 1;
    if (options[SDImageCoderEncodeCompressionQuality]) {
        compressionQuality = [options[SDImageCoderEncodeCompressionQuality] doubleValue];
    }
    BOOL encodeFirstFrame = [options[SDImageCoderEncodeFirstFrameOnly] boolValue];
    
    return [self sd_encodedFLIFDataWithImage:image quality:compressionQuality encodeFirstFrame:encodeFirstFrame];
}

- (nullable NSData *)sd_encodedFLIFDataWithImage:(nonnull UIImage *)image quality:(double)quality encodeFirstFrame:(BOOL)encodeFirstFrame {
    
    FLIF_ENCODER *encoder = flif_create_encoder();
    if (!encoder) {
        return nil;
    }
    
    // libflif 0 means lossless (1.0 for our quality), and 100 means max compression (0.0 for our quality)
    int32_t loss = (1 - quality) * 100;
    flif_encoder_set_lossy(encoder, loss);
    /**
     This is the option to fix the issue due to old version. We keep it as a property.
     "This animated FLIF will probably not be properly decoded by older FLIF decoders (version < 0.3) since they have a bug in this particular combination of transformations.
     If backwards compatibility is important, you can use the option -B to avoid the issue"
     */
    flif_encoder_set_auto_color_buckets(encoder, !self.disableColorBuckets);
    
    NSArray<SDImageFrame *> *frames = [SDImageCoderHelper framesFromAnimatedImage:image];
    
    if (encodeFirstFrame || frames.count == 0) {
        // for static FLIF image
        FLIF_IMAGE *flifimage = [self sd_encodedFLIFFrameWithImage:image];
        if (!flifimage) {
            flif_destroy_encoder(encoder);
            return nil;
        }
        flif_encoder_add_image(encoder, flifimage);
        flif_destroy_image(flifimage);
    } else {
        // for aniamted FLIF image
        for (size_t i = 0; i < frames.count; i++) {
            @autoreleasepool {
                SDImageFrame *currentFrame = frames[i];
                FLIF_IMAGE *flifimage = [self sd_encodedFLIFFrameWithImage:currentFrame.image];
                if (!flifimage) {
                    flif_destroy_encoder(encoder);
                    return nil;
                }
                // libflif frame duration is milliseconds
                uint32_t delay = currentFrame.duration * 1000;
                flif_image_set_frame_delay(flifimage, delay);
                flif_encoder_add_image(encoder, flifimage);
                flif_destroy_image(flifimage);
            }
        }
    }
    
    void *dataBuffer;
    size_t dataSize;
    
    int32_t result = flif_encoder_encode_memory(encoder, &dataBuffer, &dataSize);
    flif_destroy_encoder(encoder);
    if (!result) {
        return nil;
    }
    
    NSData *data = [NSData dataWithBytes:dataBuffer length:dataSize];
    free(dataBuffer);
    
    return data;
}

- (FLIF_IMAGE *)sd_encodedFLIFFrameWithImage:(nonnull UIImage *)image {
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) {
        return nil;
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    
    // libheif supports RGB888/RGBA8888 color mode, convert all to this
    vImageConverterRef convertor = NULL;
    vImage_Error v_error = kvImageNoError;
    
    vImage_CGImageFormat srcFormat = {
        .bitsPerComponent = (uint32_t)CGImageGetBitsPerComponent(imageRef),
        .bitsPerPixel = (uint32_t)CGImageGetBitsPerPixel(imageRef),
        .colorSpace = CGImageGetColorSpace(imageRef),
        .bitmapInfo = bitmapInfo
    };
    vImage_CGImageFormat destFormat = {
        .bitsPerComponent = 8,
        .bitsPerPixel = hasAlpha ? 32 : 24,
        .colorSpace = [SDImageCoderHelper colorSpaceGetDeviceRGB],
        .bitmapInfo = hasAlpha ? kCGImageAlphaLast | kCGBitmapByteOrderDefault : kCGImageAlphaNone | kCGBitmapByteOrderDefault // RGB888/RGBA8888 (Non-premultiplied to works for libwebp)
    };
    
    convertor = vImageConverter_CreateWithCGImageFormat(&srcFormat, &destFormat, NULL, kvImageNoFlags, &v_error);
    if (v_error != kvImageNoError) {
        return nil;
    }
    
    vImage_Buffer src;
    v_error = vImageBuffer_InitWithCGImage(&src, &srcFormat, NULL, imageRef, kvImageNoFlags);
    if (v_error != kvImageNoError) {
        return nil;
    }
    vImage_Buffer dest = {
        .width = width,
        .height = height,
        .rowBytes = bytesPerRow,
        .data = malloc(height * bytesPerRow) // It seems that libheif does not keep 32/64 byte alignment, however, vImage's `vImageBuffer_Init` does. So manually alloc buffer
    };
    if (!dest.data) {
        free(src.data);
        vImageConverter_Release(convertor);
        return nil;
    }
    
    // Convert input color mode to RGB888/RGBA8888
    v_error = vImageConvert_AnyToAny(convertor, &src, &dest, NULL, kvImageNoFlags);
    vImageConverter_Release(convertor);
    if (v_error != kvImageNoError) {
        free(src.data);
        free(dest.data);
        return nil;
    }
    
    free(src.data);
    void * rgba = dest.data; // Converted buffer
    
    FLIF_IMAGE *flifimage;
    if (hasAlpha) {
        flifimage = flif_import_image_RGBA((uint32_t)width, (uint32_t)height, rgba, (uint32_t)bytesPerRow);
    } else {
        flifimage = flif_import_image_RGB((uint32_t)width, (uint32_t)height, rgba, (uint32_t)bytesPerRow);
    }
    
    // free the rgba buffer
    free(rgba);
    
    return flifimage;
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
