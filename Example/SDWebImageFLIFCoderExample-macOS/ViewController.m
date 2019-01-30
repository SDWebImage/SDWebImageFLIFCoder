//
//  ViewController.m
//  SDWebImageFLIFCoderExample-macOS
//
//  Created by lizhuoli on 2019/1/30.
//  Copyright © 2019 lizhuoli1126@126.com. All rights reserved.
//

#import "ViewController.h"
#import <SDWebImageFLIFCoder/SDWebImageFLIFCoder.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    SDImageFLIFCoder *FLIFCoder = [SDImageFLIFCoder sharedCoder];
    [[SDImageCodersManager sharedManager] addCoder:FLIFCoder];
    NSURL *staticFLIFURL = [NSURL URLWithString:@"https://raw.githubusercontent.com/sveinbjornt/Phew/master/sample-images/kodim07.flif"];
    NSURL *animatedFLIFURL = [NSURL URLWithString:@"https://raw.githubusercontent.com/sveinbjornt/Phew/master/sample-images/train.flif"];
    
    CGSize screenSize = self.view.bounds.size;
    
    UIImageView *imageView1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width / 2, screenSize.height)];
    imageView1.imageScaling = NSImageScaleProportionallyUpOrDown;
    
    UIImageView *imageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(screenSize.width / 2, 0, screenSize.width / 2, screenSize.height)];
    imageView2.imageScaling = NSImageScaleProportionallyUpOrDown;
    
    [self.view addSubview:imageView1];
    [self.view addSubview:imageView2];
    
    [imageView1 sd_setImageWithURL:staticFLIFURL completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image) {
            NSLog(@"Static FLIF load success");
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *FLIFData = [SDImageFLIFCoder.sharedCoder encodedDataWithImage:image format:SDImageFormatFLIF options:nil];
                if (FLIFData) {
                    NSLog(@"Static FLIF encode success");
                }
            });
        }
    }];
    [imageView2 sd_setImageWithURL:animatedFLIFURL completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image.sd_isAnimated) {
            NSLog(@"Animated FLIF load success");
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // Animated FLIF encoding is really slow, specify the lowest quality with fast speed
                NSData *FLIFData = [SDImageFLIFCoder.sharedCoder encodedDataWithImage:image format:SDImageFormatFLIF options:@{SDImageCoderEncodeCompressionQuality : @(0)}];
                if (FLIFData) {
                    NSLog(@"Animated FLIF encode success");
                }
            });
        }
    }];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
