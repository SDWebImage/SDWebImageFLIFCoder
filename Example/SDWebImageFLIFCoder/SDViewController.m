//
//  SDViewController.m
//  SDWebImageFLIFCoder
//
//  Created by lizhuoli1126@126.com on 01/30/2019.
//  Copyright (c) 2019 lizhuoli1126@126.com. All rights reserved.
//

#import "SDViewController.h"
#import <SDWebImageFLIFCoder/SDWebImageFLIFCoder.h>

@interface SDViewController ()

@end

@implementation SDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    SDImageFLIFCoder *FLIFCoder = [SDImageFLIFCoder sharedCoder];
    [[SDImageCodersManager sharedManager] addCoder:FLIFCoder];
    NSURL *staticFLIFURL = [NSURL URLWithString:@"https://raw.githubusercontent.com/sveinbjornt/Phew/master/sample-images/kodim07.flif"];
    NSURL *animatedFLIFURL = [NSURL URLWithString:@"https://raw.githubusercontent.com/sveinbjornt/Phew/master/sample-images/train.flif"];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    UIImageView *imageView1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height / 2)];
    UIImageView *imageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(0, screenSize.height / 2, screenSize.width, screenSize.height / 2)];
    
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
        if (image.images) {
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
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
