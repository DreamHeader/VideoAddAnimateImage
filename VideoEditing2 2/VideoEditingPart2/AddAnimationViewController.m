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

#define Opacity_Animate @"opacity"
#define RotationZ_Animate @"transform.rotation.z"
#define RotationX_Animate @"transform.rotation.x"
#define TranslationX_Animate @"transform.translation.x"
#define Scale_Animate @"transform.scale"
#define Position_Animate @"position"

@interface AddAnimationViewController () <CAAnimationDelegate>

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
  CGFloat totalTime = 4.0;  // [gifInfo[@"totalTime"] doubleValue];
  NSMutableArray* mutArray = [NSMutableArray array];
  for (int i = 1; i < 82; i++) {
    UIImage* image =
        [UIImage imageNamed:[NSString stringWithFormat:@"zhiHe_%d@2x.png", i]];
    if (image) {
      [mutArray addObject:@{ @"image" : image, @"delay" : @(0.04) }];
    }
  }
  NSArray* imageInfoList = [mutArray copy];  // gifInfo[@"imageList"];
  if (imageInfoList.count == 0 || totalTime < 0.01) {
    return nil;
  }
  CALayer* imageLayer1 = [CALayer layer];
  imageLayer1.frame = CGRectMake(0, 360, 750, 360);
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
#pragma mark - 动画
// opacity动画
- (CABasicAnimation*)setUpOpacityAnimateFromValue:(double)fromValue
                                          toValue:(double)toValue
                                         duration:(CFTimeInterval)duration {
  CABasicAnimation* animation =
      [CABasicAnimation animationWithKeyPath:@"opacity"];
  animation.fromValue = @(fromValue);
  animation.toValue = @(toValue);
  animation.duration = duration;
  animation.autoreverses = NO;
  animation.repeatCount = 1;
  animation.removedOnCompletion = NO;
  animation.fillMode = kCAFillModeForwards;
  return animation;
}
// 动画
- (CABasicAnimation*)setUpAnimateFromValue:(id)fromValue
                                   toValue:(id)toValue
                                  duration:(CFTimeInterval)duration
                                animateKey:(NSString*)animateKey
                                 beginTime:(CFTimeInterval)beginTime {
  CABasicAnimation* animation =
      [CABasicAnimation animationWithKeyPath:animateKey];
  animation.fromValue = fromValue;
  animation.toValue = toValue;
  animation.duration = duration;
  animation.autoreverses = NO;
  animation.repeatCount = 1;
  animation.beginTime = beginTime;
  animation.removedOnCompletion = NO;
  animation.fillMode = kCAFillModeForwards;
  return animation;
}
#pragma mark - 组装视频动画
- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition*)composition
                                  size:(CGSize)size {
  NSMutableArray* origionalImages = [NSMutableArray arrayWithCapacity:0];
  NSMutableArray* blureImages = [NSMutableArray arrayWithCapacity:0];
  for (NSInteger i = 1; i < 11; i++) {
    NSString* imageName = [NSString stringWithFormat:@"videoImage%@.jpg", @(i)];
    UIImage* origionalImage = [UIImage imageNamed:imageName];
    [origionalImages addObject:origionalImage];
    UIImage* blureImage = [self createBlurImage:origionalImage];
    [blureImages addObject:blureImage];
  }

  // 初始化视频layer
  CALayer* parentLayer = [CALayer layer];
  CALayer* videoLayer = [CALayer layer];
  parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
  videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
  [parentLayer addSublayer:videoLayer];

  CGFloat playTime = AVCoreAnimationBeginTimeAtZero;
  //   起始动画
  NSString* filePath =
      [[NSBundle mainBundle] pathForResource:@"videoBaiDu" ofType:@"gif"];
  CALayer* imageLayer = [self
      setUpGifImageLayerWithFilePath:filePath
                           videoSize:CGRectMake(0, 0, size.width, size.height)
                       startPlatTime:playTime
                            duration:2.18];
  if (imageLayer) {
    playTime += 2.18;
    [parentLayer addSublayer:imageLayer];
  }
  for (int i = 0; i < 9; i++) {
    UIImage* origionalImage = origionalImages[i];
    if (!origionalImage) {
      continue;
    }
    CGRect imageLayerFrame =
        [self caculateImageRatioSize:origionalImage videoSize:size];
    UIImage* blureImage = [self createBlurImage:origionalImage];
    CALayer* blureLayer = [CALayer layer];
    [blureLayer setContents:(id)[blureImage CGImage]];
    blureLayer.frame = imageLayerFrame;
    [blureLayer setAffineTransform:CGAffineTransformMakeScale(2.0, 2.0)];
    blureLayer.opacity = 0.0;
    CALayer* imageLayer = [CALayer layer];
    [imageLayer setContents:(id)[origionalImage CGImage]];
    imageLayer.frame = imageLayerFrame;
    imageLayer.opacity = 0.0;
    // 出现动画
    CABasicAnimation* showAnimation =
        [self setUpOpacityAnimateFromValue:0.0 toValue:1.0 duration:0];
    showAnimation.beginTime = playTime;
    [imageLayer addAnimation:showAnimation forKey:@"opacityShow"];
    [blureLayer addAnimation:showAnimation forKey:@"opacityShow"];
    switch (i) {
      case 0: {
        [imageLayer setAffineTransform:CGAffineTransformMakeRotation(-M_PI_4)];
        CABasicAnimation* animation1 =
            [self setUpAnimateFromValue:@(-M_PI_4)
                                toValue:@(0)
                               duration:0.85
                             animateKey:RotationZ_Animate
                              beginTime:playTime];
        [imageLayer addAnimation:animation1 forKey:@"RotationZ_Animate"];
        playTime += 1.02;
        [parentLayer addSublayer:blureLayer];
      } break;
      case 1: {
        [imageLayer setAffineTransform:CGAffineTransformMakeTranslation(
                                           imageLayer.frame.size.width / 2, 0)];

        CABasicAnimation* animation1 =
            [self setUpAnimateFromValue:@(imageLayer.frame.size.width / 2)
                                toValue:@(0)
                               duration:0.83
                             animateKey:TranslationX_Animate
                              beginTime:playTime];
        [imageLayer addAnimation:animation1 forKey:@"TranslationX_Animate"];
        [parentLayer addSublayer:blureLayer];
        playTime += 1.87;
      } break;
      case 2: {
        int animateIndex = 0;
        NSArray* fisrtArr = @[ @(0.94), @(0.03) ];
        NSArray* secondArr = @[ @(0.96), @(0.08) ];
        for (int i = 1; i < 3; i++) {
          NSArray* durationArr = (i == 1) ? fisrtArr : secondArr;
          animateIndex++;
          CABasicAnimation* animation1 =
              [self setUpAnimateFromValue:@(1)
                                  toValue:@(0.3)
                                 duration:[durationArr[0] doubleValue]
                               animateKey:Opacity_Animate
                                beginTime:playTime];
          [imageLayer
              addAnimation:animation1
                    forKey:[NSString stringWithFormat:@"Opacity_Animate%d",
                                                      animateIndex]];
          playTime += [durationArr[0] doubleValue];
          animateIndex++;
          CABasicAnimation* animation2 =
              [self setUpAnimateFromValue:@(0.3)
                                  toValue:@(1.0)
                                 duration:[durationArr[1] doubleValue]
                               animateKey:Opacity_Animate
                                beginTime:playTime];
          [imageLayer
              addAnimation:animation2
                    forKey:[NSString stringWithFormat:@"Opacity_Animate%d",
                                                      animateIndex]];
          playTime += [durationArr[1] doubleValue];
          [parentLayer addSublayer:blureLayer];
        }
      }
        playTime += 0.05;
        break;
      case 3: {
        [imageLayer setAffineTransform:CGAffineTransformMakeScale(0.7, 0.7)];
        CABasicAnimation* animation1 = [self setUpAnimateFromValue:@(0.7)
                                                           toValue:@(1.0)
                                                          duration:0.98
                                                        animateKey:Scale_Animate
                                                         beginTime:playTime];
        [imageLayer addAnimation:animation1 forKey:@"Scale_Animate"];
        playTime += 1.04;
        [parentLayer addSublayer:blureLayer];
      }

      break;
      case 4: {
        [imageLayer setAffineTransform:CGAffineTransformMakeTranslation(
                                           imageLayer.frame.size.width / 2,
                                           -imageLayer.frame.size.height / 2)];
        CABasicAnimation* animation1 = [self
            setUpAnimateFromValue:[NSValue valueWithCGPoint:imageLayer.position]
                          toValue:[NSValue
                                      valueWithCGPoint:CGPointMake(
                                                           0,
                                                           size.height -
                                                               imageLayerFrame
                                                                   .origin.y)]
                         duration:0.85
                       animateKey:Position_Animate
                        beginTime:playTime];
        [imageLayer addAnimation:animation1 forKey:@"Position_Animate"];
        playTime += 0.99;
        CABasicAnimation* animation2 = [self setUpAnimateFromValue:@(1.0)
                                                           toValue:@(6.0)
                                                          duration:0.87
                                                        animateKey:Scale_Animate
                                                         beginTime:playTime];
        [imageLayer addAnimation:animation2 forKey:@"Scale_Animate"];
        playTime += 0.87;

        [parentLayer addSublayer:blureLayer];
      }

      break;
      case 5: {
        [imageLayer setAffineTransform:CGAffineTransformMakeScale(6.0, 6.0)];
        CABasicAnimation* animation1 = [self setUpAnimateFromValue:@(6.0)
                                                           toValue:@(1.0)
                                                          duration:0.13
                                                        animateKey:Scale_Animate
                                                         beginTime:playTime];
        [imageLayer addAnimation:animation1 forKey:@"Scale_Animate1"];
        playTime += 0.13;
        playTime += 0.84;
        CABasicAnimation* animation2 = [self setUpAnimateFromValue:@(1.0)
                                                           toValue:@(6.0)
                                                          duration:0.12
                                                        animateKey:Scale_Animate
                                                         beginTime:playTime];
        [imageLayer addAnimation:animation2 forKey:@"Scale_Animate2"];
        playTime += 0.12;
        [parentLayer addSublayer:blureLayer];
      } break;
      case 6: {
        [imageLayer setAffineTransform:CGAffineTransformMakeScale(6.0, 6.0)];
        CABasicAnimation* animation1 = [self setUpAnimateFromValue:@(6.0)
                                                           toValue:@(1.0)
                                                          duration:0.88
                                                        animateKey:Scale_Animate
                                                         beginTime:playTime];
        [imageLayer addAnimation:animation1 forKey:@"Scale_Animate1"];
        playTime += 3.04;
        [parentLayer addSublayer:blureLayer];
      }

      break;
      case 7: {
        playTime += 3.97;
        [parentLayer addSublayer:blureLayer];
      }

      break;
      case 8: {
        playTime += 2.03;
        [parentLayer addSublayer:blureLayer];
      }
      case 9: {
        playTime += 4.83;
      } break;
      default:
        break;
    }
    CABasicAnimation* hideAnimation =
        [self setUpOpacityAnimateFromValue:1.0 toValue:0.0 duration:0];
    hideAnimation.beginTime = playTime;
    [imageLayer addAnimation:hideAnimation forKey:@"opacityHide"];
    [blureLayer addAnimation:hideAnimation forKey:@"opacityHide"];

    [parentLayer addSublayer:imageLayer];
  }
  //  // 生成弹幕
  //  for (int i = 1; i < 6; i++) {
  //    UIImage* image =
  //        [UIImage imageNamed:[NSString stringWithFormat:@"danmu%d.png", i]];
  //    CALayer* danmuLayer =
  //        [self getDanMuLayerAboutContent:image videoSize:size danmuIndex:i];
  //    [parentLayer addSublayer:danmuLayer];
  //  }
  // 生成特效
  // 纸鹤
  NSArray* texiaoNameArray = @[
    @"zhiHe_", @"HuaBan_", @"love_", @"star_", @"notes_", /* @"HuDie_",
    @"caihong_"*/
  ];
  NSArray* texiaoStartTimeArr =
      @[ @(2.19), @(5.05), @(6.18), @(2.19), @(7.22), @(12.08), @(19.21) ];
  NSArray* texiaoDurationArr =
      @[ @(3.20), @(1.13), @(1.04), @(2.86), @(4.86), @(7.04), @(3.83) ];
  NSArray* texiaoNumberArr =
      @[ @(82), @(15), @(16), @(75), @(38), @(126), @(16) ];
  for (int i = 0; i < texiaoNameArray.count; i++) {
    NSString* name = texiaoNameArray[i];
    NSNumber* number = texiaoNumberArr[i];
    NSNumber* duration = texiaoDurationArr[i];
    NSNumber* startTime = texiaoStartTimeArr[i];
    NSArray* zhiHeArray =
        [self createVideoTeXiaoArrayWithName:name count:[number intValue]];
    UIImage* firstImage = zhiHeArray.firstObject;
    CGRect frame = CGRectZero;
    switch (i) {
      case 0:
        frame = CGRectMake(0, firstImage.size.height, size.width,
                           firstImage.size.height);
        break;
      case 1:
        frame = CGRectMake(0, 0, size.width, size.height);
        break;
      case 2:
        frame = CGRectMake(0, 0, size.width, size.height);
        break;
      case 3:
        frame = CGRectMake(0, 0, size.width, size.height);
        break;
      case 4:
        frame = CGRectMake(0, 0, size.width, size.height);
        break;
      case 5:
        frame = CGRectMake(0, firstImage.size.height, size.width,
                           firstImage.size.height);
        break;
      case 6:
        frame = CGRectMake((size.width - firstImage.size.width) / 2,
                           size.height, size.width, size.height);
        break;
      default:
        break;
    }
    CALayer* zhiHeLayer =
        [self setUpGifImageLayerWithGifImage:zhiHeArray
                                   videoSize:frame
                               startPlatTime:[startTime doubleValue]
                                    duration:[duration doubleValue]];
    [parentLayer addSublayer:zhiHeLayer];
  }
  composition.animationTool = [AVVideoCompositionCoreAnimationTool
      videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
                                                              inLayer:
                                                                  parentLayer];
}
- (NSArray*)createVideoTeXiaoArrayWithName:(NSString*)name count:(int)count {
  NSMutableArray* mutArray = [[NSMutableArray alloc] init];
  for (int i = 1; i < count + 1; i++) {
    NSString* imageName = [NSString stringWithFormat:@"%@%@@2x", name, @(i)];
    //    UIImage* origionalImage = [UIImage imageNamed:imageName];
    NSString* filePath =
        [[NSBundle mainBundle] pathForResource:imageName ofType:@"png"];
    UIImage* origionalImage = [UIImage imageWithContentsOfFile:filePath];
    if (origionalImage) {
      [mutArray addObject:origionalImage];
    } else {
      NSLog(@"%@名称检查下不存在",
            [NSString stringWithFormat:@"%@%@@2x.jpg", name, @(i)]);
    }
  }
  return [mutArray copy];
}

- (CALayer*)setUpGifImageLayerWithGifImage:(NSArray*)gifImageArray
                                 videoSize:(CGRect)videoSize
                             startPlatTime:(double)startPlatTime
                                  duration:(double)duration {
  if (!gifImageArray) {
    return nil;
  }
  CGFloat totalTime = duration;
  NSMutableArray* mutArray = [NSMutableArray array];
  for (UIImage* keyImage in gifImageArray) {
    if (keyImage) {
      [mutArray addObject:@{
        @"image" : keyImage,
        @"delay" : @(duration / gifImageArray.count)
      }];
    }
  }
  NSArray* imageInfoList = [mutArray copy];
  if (imageInfoList.count == 0 || totalTime < 0.01) {
    return nil;
  }
  CALayer* imageLayer1 = [CALayer layer];
  imageLayer1.frame = videoSize;
  imageLayer1.opacity = 0.0;

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
  CABasicAnimation* showAnimation =
      [self setUpOpacityAnimateFromValue:0.0 toValue:1.0 duration:0];
  showAnimation.beginTime = startPlatTime;
  [imageLayer1 addAnimation:showAnimation forKey:@"opacityShow"];

  CAKeyframeAnimation* gifAnimation =
      [CAKeyframeAnimation animationWithKeyPath:@"contents"];
  gifAnimation.keyTimes = [keyTimeArray copy];
  gifAnimation.values = [playImageArray copy];
  gifAnimation.timingFunction =
      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  gifAnimation.duration = totalTime;
  gifAnimation.beginTime = startPlatTime;
  gifAnimation.repeatCount = 100;
  gifAnimation.removedOnCompletion = YES;
  gifAnimation.fillMode = kCAFillModeForwards;
  gifAnimation.calculationMode = kCAAnimationDiscrete;

  [imageLayer1 addAnimation:gifAnimation forKey:@"gif"];

  CABasicAnimation* hideAnimation =
      [self setUpOpacityAnimateFromValue:1.0 toValue:0.0 duration:0];
  hideAnimation.beginTime = startPlatTime + duration;
  [imageLayer1 addAnimation:hideAnimation forKey:@"opacityHide"];
  return imageLayer1;
}
- (CALayer*)setUpGifImageLayerWithFilePath:(NSString*)filePath
                                 videoSize:(CGRect)videoSize
                             startPlatTime:(double)startPlatTime
                                  duration:(double)duration {
  if (!filePath) {
    return nil;
  }
  CGFloat playTime = startPlatTime;
  NSData* gifData = [NSData dataWithContentsOfFile:filePath];
  CALayer* imageLayer = [CALayer layer];
  if (!gifData) {
    return nil;
  }
  NSDictionary* gifInfo = [ISGifToImageInfoTool getGifInfoWithSource:gifData];
  CGFloat totalTime = [gifInfo[@"totalTime"] doubleValue];
  NSArray* imageInfoList = gifInfo[@"imageList"];
  if (imageInfoList.count > 0 && totalTime > 0.01) {
    imageLayer.frame = videoSize;
    imageLayer.opacity = 1.0;

    CGFloat durationTime = duration;
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
    gifAnimation.delegate = self;
    gifAnimation.calculationMode = kCAAnimationDiscrete;
    [imageLayer addAnimation:gifAnimation forKey:@"gif"];
    playTime += durationTime;

    CABasicAnimation* animation =
        [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = @(1.0);
    animation.toValue = @(0.0);
    animation.duration = 0;
    animation.repeatCount = 1;
    animation.beginTime = playTime;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    [imageLayer addAnimation:animation forKey:@"gifRemove"];
  }
  return imageLayer;
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
  CGFloat yCoordiante = videoHeight - 880;
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
