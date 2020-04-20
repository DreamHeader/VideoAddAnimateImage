//
//  AddAnimationViewController.m
//  VideoEditingPart2
//
//  Created by Abdul Azeem Khan on 1/24/13.
//  Copyright (c) 2013 com.datainvent. All rights reserved.
//

#import "AddAnimationViewController.h"
#import <CoreImage/CoreImage.h>

#import "FLLayerBuilderTool.h"
#import "ISGifToImageInfoTool.h"
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
@interface AddAnimationViewController ()

@end

@implementation AddAnimationViewController

- (IBAction)loadAsset:(id)sender {
  [self startMediaBrowserFromViewController:self usingDelegate:self];
}

- (IBAction)generateOutput:(id)sender {
  [self videoOutput];
}
- (CGRect)caculateImageRatioSize:(UIImage*)image videoSize:(CGSize)size {
  if (!image || size.height == 0 || size.width == 0) {
    return CGRectZero;
  }

  CGRect newRect = CGRectZero;
  CGSize ratioSize = CGSizeZero;

  CGFloat newWidth = 0.0;
  CGFloat newHeight = 0.0;
  // 视频高宽比
  CGFloat standardRatioValue = size.height / size.width;
  CGSize imageSize = image.size;
  CGFloat imageRatioValue = imageSize.height / imageSize.width;
  // 如果大于 意味着这个图片是高特别大的图
  if (imageRatioValue > standardRatioValue) {
    newHeight = size.height;
    newWidth = size.height * (imageSize.width / imageSize.height);
    ratioSize = CGSizeMake(newWidth, newHeight);
  } else if (imageRatioValue < standardRatioValue) {
    // 如果小于 意味着这个图片是宽特别大的图
    newWidth = size.width;
    newHeight = newWidth * (imageSize.height / imageSize.width);
    ratioSize = CGSizeMake(newWidth, newHeight);
  } else {
    ratioSize = size;
  }

  CGFloat xCoordinate =
      size.width > ratioSize.width ? (size.width - ratioSize.width) / 2 : 0;
  CGFloat yCoordinate =
      size.height > ratioSize.height ? (size.height - ratioSize.height) / 2 : 0;
  newRect =
      CGRectMake(xCoordinate, yCoordinate, ratioSize.width, ratioSize.height);

  return newRect;
}
- (CALayer*)addOneGif {
  NSString* filePath =
      [[NSBundle mainBundle] pathForResource:@"rainbow" ofType:@"gif"];
  NSData* gifData = [NSData dataWithContentsOfFile:filePath];
  if (!gifData) {
    return nil;
  }
  NSDictionary* gifInfo = [ISGifToImageInfoTool getGifInfoWithSource:gifData];
  CGFloat totalTime =
      1.6000000238418579;  // [gifInfo[@"totalTime"] doubleValue];
  NSMutableArray* mutArray = [NSMutableArray array];
  for (int i = 101; i < 175; i++) {
    UIImage* image =
        [UIImage imageNamed:[NSString stringWithFormat:@"星星%d.png", i]];
    if (image) {
      [mutArray addObject:@{ @"image" : image, @"delay" : @(0.1) }];
    }
  }
  NSArray* imageInfoList = [mutArray copy];  // gifInfo[@"imageList"];
  if (imageInfoList.count == 0 || totalTime < 0.01) {
    return nil;
  }
  CALayer* imageLayer1 = [CALayer layer];
  imageLayer1.frame = CGRectMake(200, 200, 750, 1334);
  // [imageLayer1 setAffineTransform:CGAffineTransformMakeRotation(M_PI_4)];
  imageLayer1.opacity = 1.0;

  CGFloat currentTime = totalTime;
  CGFloat gifPlayTime = 0.0;

  NSMutableArray* playImageArray = [NSMutableArray array];
  NSMutableArray* keyTimeArray = [NSMutableArray array];
  NSMutableArray* imageArray = [NSMutableArray array];

  for (NSInteger i = 0; i < imageInfoList.count; i++) {
    NSDictionary* imageInfo = imageInfoList[i];
    CGImageRef cgImage = [(UIImage*)imageInfo[@"image"] CGImage];
    [imageArray addObject:imageInfo[@"image"]];
    if (cgImage) {
      CGFloat time = [imageInfo[@"delay"] doubleValue];
      [playImageArray addObject:(__bridge id _Nonnull)cgImage];
      [keyTimeArray addObject:@(gifPlayTime / totalTime)];
      gifPlayTime += time;
    }
  }

  CAKeyframeAnimation* gifAnimation =
      [CAKeyframeAnimation animationWithKeyPath:@"contents"];
  gifAnimation.keyTimes = [keyTimeArray copy];
  gifAnimation.values = [playImageArray copy];
  gifAnimation.timingFunction =
      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  gifAnimation.duration = currentTime;
  gifAnimation.beginTime = AVCoreAnimationBeginTimeAtZero;
  gifAnimation.repeatCount = 100;
  gifAnimation.removedOnCompletion = YES;
  gifAnimation.fillMode = kCAFillModeForwards;
  gifAnimation.calculationMode = kCAAnimationDiscrete;

  [imageLayer1 addAnimation:gifAnimation forKey:@"gif"];

  return imageLayer1;
}
- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition*)composition
                                  size:(CGSize)size {
  //  NSMutableArray* origionalImages = [NSMutableArray arrayWithCapacity:0];
  //  NSMutableArray* blureImages = [NSMutableArray arrayWithCapacity:0];
  //  for (NSInteger i = 1; i < 3; i++) {
  //    NSString* imageName = [NSString stringWithFormat:@"pic_%@.jpg", @(i)];
  //    UIImage* origionalImage = [UIImage imageNamed:imageName];
  //    [origionalImages addObject:origionalImage];
  //    UIImage* blureImage = [self blureImage:origionalImage withInputRadius:0.6];
  //    [blureImages addObject:blureImage];
  //  }

  // 初始化视频layer
  CALayer* parentLayer = [CALayer layer];
  CALayer* videoLayer = [CALayer layer];
  parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
  videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
  [parentLayer addSublayer:videoLayer];

  CGFloat playTime = AVCoreAnimationBeginTimeAtZero;
  //   起始动画
  NSString* filePath =
      [[NSBundle mainBundle] pathForResource:@"baidu" ofType:@"gif"];
  NSData* gifData = [NSData dataWithContentsOfFile:filePath];
  CALayer* imageLayer = [CALayer layer];
  if (gifData) {
    NSDictionary* gifInfo = [ISGifToImageInfoTool getGifInfoWithSource:gifData];
    CGFloat totalTime = [gifInfo[@"totalTime"] doubleValue];
    NSArray* imageInfoList = gifInfo[@"imageList"];
    if (imageInfoList.count > 0 && totalTime > 0.01) {
      imageLayer.frame = CGRectMake(0, 0, size.width, size.height);
      imageLayer.opacity = 1.0;

      CGFloat durationTime = 2.18;
      CGFloat gifPlayTime = 0.0;

      NSMutableArray* playImageArray = [NSMutableArray array];
      NSMutableArray* keyTimeArray = [NSMutableArray array];
      NSMutableArray* imageArray = [NSMutableArray array];
      for (NSInteger i = 0; i < imageInfoList.count; i++) {
        NSDictionary* imageInfo = imageInfoList[i];
        CGImageRef cgImage = [(UIImage*)imageInfo[@"image"] CGImage];
        [imageArray addObject:imageInfo[@"image"]];
        if (cgImage) {
          CGFloat time = [imageInfo[@"delay"] doubleValue];
          [playImageArray addObject:(__bridge id _Nonnull)cgImage];
          [keyTimeArray addObject:@(gifPlayTime / totalTime)];
          gifPlayTime += time;
        }
      }
      CAKeyframeAnimation* gifAnimation =
          [CAKeyframeAnimation animationWithKeyPath:@"contents"];
      gifAnimation.keyTimes = [keyTimeArray copy];
      gifAnimation.values = [playImageArray copy];
      gifAnimation.timingFunction =
          [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
      gifAnimation.duration = durationTime;
      gifAnimation.beginTime = playTime;
      gifAnimation.repeatCount = 100;
      gifAnimation.removedOnCompletion = YES;
      gifAnimation.fillMode = kCAFillModeForwards;
      gifAnimation.calculationMode = kCAAnimationDiscrete;
      [imageLayer addAnimation:gifAnimation forKey:@"gif"];
      playTime += durationTime;

      CABasicAnimation* animation =
          [CABasicAnimation animationWithKeyPath:@"opacity"];
      animation.fromValue = @(1.0);
      animation.toValue = @(0.0);
      //  animation4.autoreverses = YES;
      animation.duration = 0;
      animation.repeatCount = 1;
      animation.beginTime = playTime;
      animation.removedOnCompletion = NO;
      animation.fillMode = kCAFillModeForwards;
      [imageLayer addAnimation:animation forKey:@"gifRemove"];

      [parentLayer addSublayer:imageLayer];
    }
  }
  playTime += 0.01;
  // 第一张
  UIImage* origionalImage1 = [UIImage imageNamed:@"7.jpg"];
  UIImage* blureImage1 = [self createBlurImage:origionalImage1];

  CALayer* blureLayer1 = [CALayer layer];
  [blureLayer1 setContents:(id)[blureImage1 CGImage]];

  blureLayer1.frame =
      CGRectMake(-(size.width * 0.2) / 2, -(size.height * 0.2) / 2,
                 size.width * 1.2, size.height * 1.2);
  blureLayer1.opacity = 0.0;
  CALayer* imageLayer1 = [CALayer layer];
  [imageLayer1 setContents:(id)[origionalImage1 CGImage]];
  imageLayer1.frame =
      [self caculateImageRatioSize:origionalImage1 videoSize:size];
  [imageLayer1 setAffineTransform:CGAffineTransformMakeRotation(-M_PI_4)];
  imageLayer1.opacity = 0.0;

  CABasicAnimation* animation =
      [CABasicAnimation animationWithKeyPath:@"opacity"];
  animation.fromValue = @(0.0);
  animation.toValue = @(1.0);
  //  animation4.autoreverses = YES;
  animation.duration = 0;
  animation.repeatCount = 1;
  animation.beginTime = playTime;
  animation.removedOnCompletion = NO;
  animation.fillMode = kCAFillModeForwards;
  [imageLayer1 addAnimation:animation forKey:@"a0"];
  [blureLayer1 addAnimation:animation forKey:@"a0"];

  CABasicAnimation* animation1 =
      [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
  animation1.fromValue = @(M_PI_4);
  animation1.toValue = @(0);
  animation1.autoreverses = NO;
  animation1.duration = 1;
  animation1.repeatCount = 1;
  animation1.beginTime = playTime;
  animation1.removedOnCompletion = NO;
  animation1.fillMode = kCAFillModeForwards;
  [imageLayer1 addAnimation:animation1 forKey:@"a1"];
  playTime += 1.5;

  CABasicAnimation* animation2 =
      [CABasicAnimation animationWithKeyPath:@"transform.scale"];
  animation2.fromValue = @(1);
  animation2.toValue = @(0.5);
  animation2.duration = 0.25;
  animation2.beginTime = playTime;
  animation2.removedOnCompletion = NO;
  animation2.fillMode = kCAFillModeForwards;
  [imageLayer1 addAnimation:animation2 forKey:@"a2"];
  playTime += 0.25;

  CABasicAnimation* animation3 =
      [CABasicAnimation animationWithKeyPath:@"transform.scale"];
  animation3.fromValue = @(0.5);
  animation3.toValue = @(1.5);
  animation3.duration = 0.25;
  animation3.beginTime = playTime;
  animation3.removedOnCompletion = NO;
  animation3.fillMode = kCAFillModeForwards;
  [imageLayer1 addAnimation:animation3 forKey:@"a3"];
  playTime += 0.25;

  CABasicAnimation* animation4 =
      [CABasicAnimation animationWithKeyPath:@"opacity"];
  animation4.fromValue = @(1.0);
  animation4.toValue = @(0.0);
  //  animation4.autoreverses = YES;
  animation4.duration = 0;
  animation4.repeatCount = 1;
  animation4.beginTime = playTime;
  animation4.removedOnCompletion = NO;
  animation4.fillMode = kCAFillModeForwards;
  [imageLayer1 addAnimation:animation4 forKey:@"a4"];
  [blureLayer1 addAnimation:animation4 forKey:@"a4"];

  [parentLayer addSublayer:blureLayer1];
  [parentLayer addSublayer:imageLayer1];

  // 第二张
  {
    UIImage* origionalImage2 = [UIImage imageNamed:@"1.jpg"];
    UIImage* blureImage2 = [self createBlurImage:origionalImage2];

    CALayer* blureLayer2 = [CALayer layer];
    [blureLayer2 setContents:(id)[blureImage2 CGImage]];

    blureLayer2.frame =
        CGRectMake(-(size.width * 0.2) / 2, -(size.height * 0.2) / 2,
                   size.width * 1.2, size.height * 1.2);
    blureLayer2.opacity = 0.0;

    CALayer* imageLayer2 = [CALayer layer];
    [imageLayer2 setContents:(id)[origionalImage2 CGImage]];
    imageLayer2.frame =
        [self caculateImageRatioSize:origionalImage2 videoSize:size];
    [imageLayer2 setAffineTransform:CGAffineTransformMakeScale(0.7, 0.7)];
    imageLayer2.opacity = 0.0;

    CABasicAnimation* animationTwo0 =
        [CABasicAnimation animationWithKeyPath:@"opacity"];
    animationTwo0.fromValue = @(0.0);
    animationTwo0.toValue = @(1.0);
    animationTwo0.autoreverses = NO;
    animationTwo0.duration = 0;
    animationTwo0.repeatCount = 1;
    animationTwo0.beginTime = playTime;
    animationTwo0.removedOnCompletion = NO;
    animationTwo0.fillMode = kCAFillModeForwards;
    [imageLayer2 addAnimation:animationTwo0 forKey:@"b0"];
    [blureLayer2 addAnimation:animationTwo0 forKey:@"b0"];

    CABasicAnimation* animationTwo1 =
        [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animationTwo1.fromValue = @(0.7);
    animationTwo1.toValue = @(1);
    animationTwo1.autoreverses = NO;
    animationTwo1.duration = 1;
    animationTwo1.repeatCount = 1;
    animationTwo1.beginTime = playTime;
    animationTwo1.removedOnCompletion = NO;
    animationTwo1.fillMode = kCAFillModeForwards;
    [imageLayer2 addAnimation:animationTwo1 forKey:@"b1"];
    playTime += 1.0;

    CABasicAnimation* animationTwo2 =
        [CABasicAnimation animationWithKeyPath:@"opacity"];
    animationTwo2.fromValue = @(1);
    animationTwo2.toValue = @(0.1);
    animationTwo2.duration = 0.5;
    animationTwo2.autoreverses = NO;
    animationTwo2.beginTime = playTime;
    animationTwo2.removedOnCompletion = NO;
    animationTwo2.fillMode = kCAFillModeForwards;
    [imageLayer2 addAnimation:animationTwo2 forKey:@"b2"];
    playTime += 0.5;

    CABasicAnimation* animationTwo3 =
        [CABasicAnimation animationWithKeyPath:@"opacity"];
    animationTwo3.fromValue = @(0.1);
    animationTwo3.toValue = @(1.0);
    animationTwo3.duration = 0.5;
    animationTwo3.beginTime = playTime;
    animationTwo3.autoreverses = NO;
    animationTwo3.removedOnCompletion = NO;
    animationTwo3.fillMode = kCAFillModeForwards;
    [imageLayer2 addAnimation:animationTwo3 forKey:@"b3"];
    playTime += 1;

    CABasicAnimation* animationTwo4 =
        [CABasicAnimation animationWithKeyPath:@"opacity"];
    animationTwo4.fromValue = @(1.0);
    animationTwo4.toValue = @(0.0);
    animationTwo4.duration = 0;
    animationTwo4.repeatCount = 1;
    animationTwo4.autoreverses = NO;
    animationTwo4.beginTime = playTime;
    animationTwo4.removedOnCompletion = NO;
    animationTwo4.fillMode = kCAFillModeForwards;
    [imageLayer2 addAnimation:animationTwo4 forKey:@"b4"];
    [blureLayer2 addAnimation:animationTwo4 forKey:@"b4"];

    [parentLayer addSublayer:blureLayer2];
    [parentLayer addSublayer:imageLayer2];
  }
  // 第三张
  UIImage* origionalImage3 = [UIImage imageNamed:@"6.jpg"];
  UIImage* blureImage3 = [self createBlurImage:origionalImage3];

  CALayer* blureLayer3 = [CALayer layer];
  [blureLayer3 setContents:(id)[blureImage3 CGImage]];

  blureLayer3.frame =
      CGRectMake(-(size.width * 0.2) / 2, -(size.height * 0.2) / 2,
                 size.width * 1.2, size.height * 1.2);
  blureLayer3.opacity = 0.0;

  CALayer* imageLayer3 = [CALayer layer];
  [imageLayer3 setContents:(id)[origionalImage3 CGImage]];
  imageLayer3.frame =
      [self caculateImageRatioSize:origionalImage3 videoSize:size];
  imageLayer3.opacity = 0.0;

  CABasicAnimation* animationThree0 =
      [CABasicAnimation animationWithKeyPath:@"opacity"];
  animationThree0.fromValue = @(0.0);
  animationThree0.toValue = @(1.0);
  animationThree0.autoreverses = NO;
  animationThree0.duration = 0;
  animationThree0.repeatCount = 1;
  animationThree0.beginTime = playTime;
  animationThree0.removedOnCompletion = NO;
  animationThree0.fillMode = kCAFillModeForwards;
  [imageLayer3 addAnimation:animationThree0 forKey:@"c0"];
  [blureLayer3 addAnimation:animationThree0 forKey:@"c0"];
  playTime += 0.5;

  int animateIndex = 0;
  for (int i = 1; i < 3; i++) {
    animateIndex++;
    CABasicAnimation* animationThree1 =
        [CABasicAnimation animationWithKeyPath:@"opacity"];
    animationThree1.fromValue = @(1);
    animationThree1.toValue = @(0.1);
    animationThree1.duration = 0.25;
    animationThree1.autoreverses = NO;
    animationThree1.beginTime = playTime;
    animationThree1.removedOnCompletion = NO;
    animationThree1.fillMode = kCAFillModeForwards;
    [imageLayer3 addAnimation:animationThree1
                       forKey:[NSString stringWithFormat:@"c%d", animateIndex]];
    playTime += 0.25;
    animateIndex++;
    CABasicAnimation* animationThree2 =
        [CABasicAnimation animationWithKeyPath:@"opacity"];
    animationThree2.fromValue = @(0.1);
    animationThree2.toValue = @(1.0);
    animationThree2.duration = 0.25;
    animationThree2.beginTime = playTime;
    animationThree2.autoreverses = NO;
    animationThree2.removedOnCompletion = NO;
    animationThree2.fillMode = kCAFillModeForwards;
    [imageLayer3 addAnimation:animationThree2
                       forKey:[NSString stringWithFormat:@"c%d", animateIndex]];
    playTime += 0.25;
  }
  playTime += 0.5;

  CABasicAnimation* animationThree3 =
      [CABasicAnimation animationWithKeyPath:@"opacity"];
  animationThree3.fromValue = @(1.0);
  animationThree3.toValue = @(0.0);
  animationThree3.duration = 0;
  animationThree3.repeatCount = 1;
  animationThree3.autoreverses = NO;
  animationThree3.beginTime = playTime;
  animationThree3.removedOnCompletion = NO;
  animationThree3.fillMode = kCAFillModeForwards;
  [imageLayer3 addAnimation:animationThree3 forKey:@"a8"];
  [blureLayer3 addAnimation:animationThree3 forKey:@"a8"];

  [parentLayer addSublayer:blureLayer3];
  [parentLayer addSublayer:imageLayer3];
  //  第四张
  UIImage* origionalImage4 = [UIImage imageNamed:@"3.jpg"];
  UIImage* blureImage4 = [self createBlurImage:origionalImage4];

  CALayer* blureLayer4 = [CALayer layer];
  [blureLayer4 setContents:(id)[blureImage4 CGImage]];

  blureLayer4.frame =
      CGRectMake(-(size.width * 0.2) / 2, -(size.height * 0.2) / 2,
                 size.width * 1.2, size.height * 1.2);
  blureLayer4.opacity = 0.0;

  CALayer* imageLayer4 = [CALayer layer];
  [imageLayer4 setContents:(id)[origionalImage4 CGImage]];
  imageLayer4.frame =
      [self caculateImageRatioSize:origionalImage4 videoSize:size];
  [imageLayer4 setAffineTransform:CGAffineTransformMakeTranslation(
                                      imageLayer4.frame.size.width / 2, 0)];
  imageLayer4.opacity = 0.0;

  CABasicAnimation* animationFour0 =
      [CABasicAnimation animationWithKeyPath:@"opacity"];
  animationFour0.fromValue = @(0.0);
  animationFour0.toValue = @(1.0);
  animationFour0.autoreverses = NO;
  animationFour0.duration = 0;
  animationFour0.repeatCount = 1;
  animationFour0.beginTime = playTime;
  animationFour0.removedOnCompletion = NO;
  animationFour0.fillMode = kCAFillModeForwards;
  [imageLayer4 addAnimation:animationFour0 forKey:@"d0"];
  [blureLayer4 addAnimation:animationFour0 forKey:@"d0"];
  playTime += 0.2;
  CABasicAnimation* animationFour1 =
      [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
  animationFour1.fromValue = @(imageLayer4.frame.size.width / 2);
  animationFour1.toValue = @(0);
  animationFour1.autoreverses = NO;
  animationFour1.duration = 0;
  animationFour1.repeatCount = 1;
  animationFour1.beginTime = playTime;
  animationFour1.removedOnCompletion = NO;
  animationFour1.fillMode = kCAFillModeForwards;
  [imageLayer4 addAnimation:animationFour1 forKey:@"d1"];
  playTime += 1.5;

  CABasicAnimation* animationFour2 =
      [CABasicAnimation animationWithKeyPath:@"opacity"];
  animationFour2.fromValue = @(1.0);
  animationFour2.toValue = @(0.0);
  animationFour2.duration = 0;
  animationFour2.repeatCount = 1;
  animationFour2.autoreverses = NO;
  animationFour2.beginTime = playTime;
  animationFour2.removedOnCompletion = NO;
  animationFour2.fillMode = kCAFillModeForwards;
  [imageLayer4 addAnimation:animationFour2 forKey:@"d2"];
  [blureLayer4 addAnimation:animationFour2 forKey:@"d2"];

  [parentLayer addSublayer:blureLayer4];
  [parentLayer addSublayer:imageLayer4];
  // 第五张
  UIImage* origionalImage5 = [UIImage imageNamed:@"2.jpg"];
  UIImage* blureImage5 = [self createBlurImage:origionalImage5];

  CALayer* blureLayer5 = [CALayer layer];
  [blureLayer5 setContents:(id)[blureImage5 CGImage]];

  blureLayer5.frame =
      CGRectMake(-(size.width * 0.2) / 2, -(size.height * 0.2) / 2,
                 size.width * 1.2, size.height * 1.2);
  blureLayer5.opacity = 0.0;

  CALayer* imageLayer5 = [CALayer layer];
  [imageLayer5 setContents:(id)[origionalImage5 CGImage]];
  CGRect imageLayer5Frame =
      [self caculateImageRatioSize:origionalImage5 videoSize:size];
  imageLayer5.frame = imageLayer5Frame;
  [imageLayer5 setAffineTransform:CGAffineTransformMakeTranslation(
                                      imageLayer5.frame.size.width / 2,
                                      -imageLayer5.frame.size.height / 2)];
  imageLayer5.opacity = 0.0;

  CABasicAnimation* animationFive0 =
      [CABasicAnimation animationWithKeyPath:@"opacity"];
  animationFive0.fromValue = @(0.0);
  animationFive0.toValue = @(1.0);
  animationFive0.autoreverses = NO;
  animationFive0.duration = 0;
  animationFive0.repeatCount = 1;
  animationFive0.beginTime = playTime;
  animationFive0.removedOnCompletion = NO;
  animationFive0.fillMode = kCAFillModeForwards;
  [imageLayer5 addAnimation:animationFive0 forKey:@"e0"];
  [blureLayer5 addAnimation:animationFive0 forKey:@"e0"];
  playTime += 0.1;

  CABasicAnimation* animationFive1 =
      [CABasicAnimation animationWithKeyPath:@"position"];
  animationFive1.fromValue = [NSValue valueWithCGPoint:imageLayer5.position];
  animationFive1.toValue = [NSValue
      valueWithCGPoint:CGPointMake(0, size.height - imageLayer5Frame.origin.y)];
  animationFive1.autoreverses = NO;
  animationFive1.duration = 0.5;
  animationFive1.repeatCount = 1;
  animationFive1.beginTime = playTime;
  animationFive1.removedOnCompletion = NO;
  animationFive1.fillMode = kCAFillModeForwards;
  [imageLayer5 addAnimation:animationFive1 forKey:@"e1"];
  playTime += 1.5;

  CABasicAnimation* animationFive2 =
      [CABasicAnimation animationWithKeyPath:@"transform.scale"];
  animationFive2.fromValue = @(1.0);
  animationFive2.toValue = @(6.0);
  animationFive2.autoreverses = NO;
  animationFive2.duration = 0.5;
  animationFive2.repeatCount = 1;
  animationFive2.beginTime = playTime;
  animationFive2.removedOnCompletion = NO;
  animationFive2.fillMode = kCAFillModeForwards;
  [imageLayer5 addAnimation:animationFive2 forKey:@"e2"];
  playTime += 0.5;

  CABasicAnimation* animationFive3 =
      [CABasicAnimation animationWithKeyPath:@"opacity"];
  animationFive3.fromValue = @(1.0);
  animationFive3.toValue = @(0.0);
  animationFive3.duration = 0;
  animationFive3.repeatCount = 1;
  animationFive3.autoreverses = NO;
  animationFive3.beginTime = playTime;
  animationFive3.removedOnCompletion = NO;
  animationFive3.fillMode = kCAFillModeForwards;
  [imageLayer5 addAnimation:animationFive3 forKey:@"e3"];
  [blureLayer5 addAnimation:animationFive3 forKey:@"e3"];

  [parentLayer addSublayer:blureLayer5];
  [parentLayer addSublayer:imageLayer5];
  // 第6张
  UIImage* origionalImage6 = [UIImage imageNamed:@"4.jpg"];
  UIImage* blureImage6 = [self createBlurImage:origionalImage6];

  CALayer* blureLayer6 = [CALayer layer];
  [blureLayer6 setContents:(id)[blureImage6 CGImage]];

  blureLayer6.frame =
      CGRectMake(-(size.width * 0.2) / 2, -(size.height * 0.2) / 2,
                 size.width * 1.2, size.height * 1.2);
  blureLayer6.opacity = 0.0;

  CALayer* imageLayer6 = [CALayer layer];
  [imageLayer6 setContents:(id)[origionalImage6 CGImage]];
  CGRect imageLayer6Frame =
      [self caculateImageRatioSize:origionalImage6 videoSize:size];
  imageLayer6.frame = imageLayer6Frame;
  [imageLayer6 setAffineTransform:CGAffineTransformMakeScale(6.0, 6.0)];
  imageLayer6.opacity = 0.0;

  CABasicAnimation* animationSix0 =
      [CABasicAnimation animationWithKeyPath:@"opacity"];
  animationSix0.fromValue = @(0.0);
  animationSix0.toValue = @(1.0);
  animationSix0.autoreverses = NO;
  animationSix0.duration = 0;
  animationSix0.repeatCount = 1;
  animationSix0.beginTime = playTime;
  animationSix0.removedOnCompletion = NO;
  animationSix0.fillMode = kCAFillModeForwards;
  [imageLayer6 addAnimation:animationSix0 forKey:@"f0"];
  [blureLayer6 addAnimation:animationSix0 forKey:@"f0"];

  CABasicAnimation* animationSix1 =
      [CABasicAnimation animationWithKeyPath:@"transform.scale"];
  animationSix1.fromValue = @(6.0);
  animationSix1.toValue = @(1.0);
  animationSix1.autoreverses = NO;
  animationSix1.duration = 1;
  animationSix1.repeatCount = 1;
  animationSix1.beginTime = playTime;
  animationSix1.removedOnCompletion = NO;
  animationSix1.fillMode = kCAFillModeForwards;
  [imageLayer6 addAnimation:animationSix1 forKey:@"f1"];
  playTime += 2;

  CABasicAnimation* animationSix2 =
      [CABasicAnimation animationWithKeyPath:@"opacity"];
  animationSix2.fromValue = @(1.0);
  animationSix2.toValue = @(0.0);
  animationSix2.duration = 0;
  animationSix2.repeatCount = 1;
  animationSix2.autoreverses = NO;
  animationSix2.beginTime = playTime;
  animationSix2.removedOnCompletion = NO;
  animationSix2.fillMode = kCAFillModeForwards;
  [imageLayer6 addAnimation:animationSix2 forKey:@"f2"];
  [blureLayer6 addAnimation:animationSix2 forKey:@"f2"];

  [parentLayer addSublayer:blureLayer6];
  [parentLayer addSublayer:imageLayer6];

  CALayer* animateLayer = [self addOneGif];
  [parentLayer addSublayer:animateLayer];
  // 生成弹幕

  for (int i = 1; i < 6; i++) {
    UIImage* image =
        [UIImage imageNamed:[NSString stringWithFormat:@"danmu%d.png", i]];
    CALayer* danmuLayer =
        [self getDanMuLayerAboutContent:image videoSize:size danmuIndex:i];
    [parentLayer addSublayer:danmuLayer];
  }
  composition.animationTool = [AVVideoCompositionCoreAnimationTool
      videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
                                                              inLayer:
                                                                  parentLayer];
}
- (CALayer*)getDanMuLayerAboutContent:(UIImage*)image
                            videoSize:(CGSize)videoSize
                           danmuIndex:(int)danmuIndex {
  double playTime =
      [self getDanMuStartTimeWithIndex:
                danmuIndex];  //; [self getDanMuStartTimeWithIndex:danmuIndex];

  UIImage* danmuImage = image;

  CALayer* danmuLayer = [CALayer layer];
  [danmuLayer setContents:(id)[danmuImage CGImage]];

  danmuLayer.frame =
      CGRectMake(0, 0, danmuImage.size.width, danmuImage.size.height);

  [danmuLayer
      setAffineTransform:CGAffineTransformMakeTranslation(
                             videoSize.width,
                             [self getDanMuYCoordianteWithIndex:danmuIndex
                                                    videoHeight:videoSize.height
                                                    imageHeight:danmuImage.size
                                                                    .height])];
  danmuLayer.opacity = 1.0;

  CABasicAnimation* animation0 =
      [CABasicAnimation animationWithKeyPath:@"opacity"];
  animation0.fromValue = @(1.0);
  animation0.toValue = @(1.0);
  animation0.autoreverses = NO;
  animation0.duration = 0;
  animation0.repeatCount = 1;
  animation0.beginTime = playTime;
  animation0.removedOnCompletion = NO;
  animation0.fillMode = kCAFillModeForwards;
  [danmuLayer addAnimation:animation0 forKey:@"danmu0"];

  CABasicAnimation* animation1 =
      [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
  animation1.fromValue = @(videoSize.width);
  animation1.toValue = @(-danmuImage.size.width);
  animation1.autoreverses = NO;
  animation1.duration = [self getDanMuDurationWithIndex:danmuIndex];
  animation1.repeatCount = 1;
  animation1.beginTime = playTime;
  animation1.removedOnCompletion = NO;
  animation1.fillMode = kCAFillModeForwards;
  [danmuLayer addAnimation:animation1 forKey:@"danmu1"];

  CABasicAnimation* animation2 =
      [CABasicAnimation animationWithKeyPath:@"opacity"];
  animation2.fromValue = @(1.0);
  animation2.toValue = @(0.0);
  animation2.autoreverses = NO;
  animation2.duration = 0;
  animation2.repeatCount = 1;
  animation2.beginTime = playTime + [self getDanMuDurationWithIndex:danmuIndex];
  animation2.removedOnCompletion = NO;
  animation2.fillMode = kCAFillModeForwards;
  [danmuLayer addAnimation:animation2 forKey:@"danmu2"];
  return danmuLayer;
}
- (CGFloat)getDanMuYCoordianteWithIndex:(int)index
                            videoHeight:(CGFloat)videoHeight
                            imageHeight:(CGFloat)imageHeight {
  CGFloat yCoordiante = videoHeight - 1130;
  switch (index) {
    case 1:
      break;
    case 2:
      yCoordiante -= (imageHeight + 50);
      break;
    case 3:
      yCoordiante -= (50 + imageHeight + 50 + imageHeight);
      break;
    case 4:
      yCoordiante -= (imageHeight + 50 + imageHeight + 50 + imageHeight + 50);
      break;
    case 5:
      yCoordiante += 20;
      break;
    default:
      break;
  }
  return yCoordiante;
}
- (double)getDanMuDurationWithIndex:(int)index {
  double danMuPlayTime = AVCoreAnimationBeginTimeAtZero;
  switch (index) {
    case 1:
      danMuPlayTime += 9.87;
      break;
    case 2:
      danMuPlayTime += 9.18;
      break;
    case 3:
      danMuPlayTime += 9.83;
      break;
    case 4:
      danMuPlayTime += 9.07;
      break;
    case 5:
      danMuPlayTime += 8.20;
      break;
    default:
      break;
  }
  return danMuPlayTime;
}
- (double)getDanMuStartTimeWithIndex:(int)index {
  double danMuPlayTime = AVCoreAnimationBeginTimeAtZero;
  switch (index) {
    case 1:
      danMuPlayTime += 3.16;
      break;
    case 2:
      danMuPlayTime += 3.00;
      break;
    case 3:
      danMuPlayTime += 4.20;
      break;
    case 4:
      danMuPlayTime += 4.13;
      break;
    case 5:
      danMuPlayTime += 6.71;
      break;
    default:
      break;
  }
  return danMuPlayTime;
}
- (UIImage*)createBlurImage:(UIImage*)sourceImage {
  CIImage* ciImage = [[CIImage alloc] initWithImage:sourceImage];
  CIFilter* blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
  // 将图片输入到滤镜中
  [blurFilter setValue:ciImage forKey:kCIInputImageKey];
  // 设置模糊程度
  [blurFilter setValue:@(5) forKey:@"inputRadius"];
  // 将处理之后的图片输出
  CIImage* outCiImage = [blurFilter valueForKey:kCIOutputImageKey];
  CIContext* context = [CIContext contextWithOptions:nil];
  // 获取CGImage句柄
  CGImageRef outCGImageRef =
      [context createCGImage:outCiImage fromRect:[outCiImage extent]];
  // 获取到最终图片

  UIImage* resultImage = [UIImage imageWithCGImage:outCGImageRef];

  return resultImage;
}

@end
