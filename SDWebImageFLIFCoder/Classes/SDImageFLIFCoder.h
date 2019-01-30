//
//  SDImageFLIFCoder.h
//  SDWebImageFLIFCoder
//
//  Created by lizhuoli on 2019/1/30.
//

#import <SDWebImage/SDWebImage.h>

NS_ASSUME_NONNULL_BEGIN

static const SDImageFormat SDImageFormatFLIF = 14;

@interface SDImageFLIFCoder : NSObject <SDProgressiveImageCoder>

@property (nonatomic, class, readonly, nonnull) SDImageFLIFCoder *sharedCoder;

@end

NS_ASSUME_NONNULL_END
