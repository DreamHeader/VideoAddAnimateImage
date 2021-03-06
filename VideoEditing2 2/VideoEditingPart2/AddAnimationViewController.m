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

  UIImage* bgImage = [UIImage imageNamed:@"spring_bg"];
  CALayer* bgLayer = [CALayer layer];
  [bgLayer setContents:(id)[bgImage CGImage]];
  bgLayer.frame = CGRectMake(0, 0, size.width, size.height);
  [parentLayer addSublayer:bgLayer];

  CGFloat playTime = AVCoreAnimationBeginTimeAtZero;

  // 生成动画
  for (int i = 0; i < 9; i++) {
    UIImage* origionalImage = origionalImages[i];
    if (!origionalImage) {
      continue;
    }
    // 视频图
    CALayer* bgLayer = [CALayer layer];
    bgLayer.frame = CGRectMake(0, 179, size.width, 1008);
    bgLayer.opacity = 0.0;
    bgLayer.masksToBounds = YES;
    // 内容
    CGRect imageLayerFrame = CGRectMake(45, 177, 681, 786);
    CALayer* imageLayer = [CALayer layer];
    [imageLayer setContents:(id)[origionalImage CGImage]];
    imageLayer.frame = imageLayerFrame;
    imageLayer.opacity = 1.0;
    imageLayer.contentsGravity = kCAGravityResizeAspectFill;
    [bgLayer addSublayer:imageLayer];
    // 相框
    UIImage* photoImage = [UIImage imageNamed:@"photo"];
    CGRect photoLayerFrame = CGRectMake(0, 0, 750, 1008);
    CALayer* photoLayer = [CALayer layer];
    photoLayer.opacity = 1.0;
    photoLayer.frame = photoLayerFrame;
    [photoLayer setContents:(id)[photoImage CGImage]];
    [bgLayer addSublayer:photoLayer];
    // 出现动画
    CABasicAnimation* showAnimation =
        [self setUpOpacityAnimateFromValue:0.0 toValue:1.0 duration:0];
    showAnimation.beginTime = playTime;
    [bgLayer addAnimation:showAnimation forKey:@"opacityShow"];
    switch (i) {
      case 0: {
        [bgLayer setAffineTransform:CGAffineTransformMakeScale(1.5, 1.5)];
        [bgLayer setAffineTransform:CGAffineTransformMakeRotation(-M_PI_4 / 2)];
        CABasicAnimation* animation1 = [self
            setUpAnimateFromValue:@(-M_PI_4 / 2)
                          toValue:@(0)
                         duration:
                             [self
                                 getBufferFrameTimeDurationWithStartTime:@"0:00"
                                                                endFrame:
                                                                    @"0:18"]
                       animateKey:RotationZ_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation1 forKey:@"RotationZ_Animate"];
        CABasicAnimation* animation2 = [self
            setUpAnimateFromValue:@(1.5)
                          toValue:@(0.7)
                         duration:
                             [self
                                 getBufferFrameTimeDurationWithStartTime:@"0:00"
                                                                endFrame:
                                                                    @"0:18"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation2 forKey:@"Scale_Animate"];

        playTime += [self getBufferFrameTimeDurationWithStartTime:@"0:00"
                                                         endFrame:@"0:18"];
        CABasicAnimation* animation3 = [self
            setUpAnimateFromValue:@(0.7)
                          toValue:@(1.5)
                         duration:
                             [self
                                 getBufferFrameTimeDurationWithStartTime:@"0:18"
                                                                endFrame:
                                                                    @"1:08"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation3 forKey:@"Scale_Animate"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"0:18"
                                                         endFrame:@"2:10"];
      } break;
      case 1: {
        [bgLayer setAffineTransform:CGAffineTransformMakeScale(1.5, 1.5)];
        [bgLayer setAffineTransform:CGAffineTransformMakeRotation(M_PI_4 / 2)];

        CABasicAnimation* animation1 = [self
            setUpAnimateFromValue:@(M_PI_4 / 2)
                          toValue:@(0)
                         duration:
                             [self
                                 getBufferFrameTimeDurationWithStartTime:@"2:10"
                                                                endFrame:
                                                                    @"2:22"]
                       animateKey:RotationZ_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation1 forKey:@"RotationZ_Animate"];
        CABasicAnimation* animation2 = [self
            setUpAnimateFromValue:@(1.5)
                          toValue:@(0.4)
                         duration:
                             [self
                                 getBufferFrameTimeDurationWithStartTime:@"2:10"
                                                                endFrame:
                                                                    @"2:22"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation2 forKey:@"Scale_Animate"];

        playTime += [self getBufferFrameTimeDurationWithStartTime:@"2:10"
                                                         endFrame:@"2:22"];
        CABasicAnimation* animation3 = [self
            setUpAnimateFromValue:@(0.4)
                          toValue:@(0.6)
                         duration:
                             [self
                                 getBufferFrameTimeDurationWithStartTime:@"2:22"
                                                                endFrame:
                                                                    @"3:02"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation3 forKey:@"Scale_Animate1"];

        playTime += [self getBufferFrameTimeDurationWithStartTime:@"2:22"
                                                         endFrame:@"3:02"];

        CABasicAnimation* animation4 = [self
            setUpAnimateFromValue:@(0.6)
                          toValue:@(0.4)
                         duration:
                             [self
                                 getBufferFrameTimeDurationWithStartTime:@"3:02"
                                                                endFrame:
                                                                    @"3:03"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation4 forKey:@"Scale_Animate2"];

        playTime += [self getBufferFrameTimeDurationWithStartTime:@"3:02"
                                                         endFrame:@"3:03"];

        CABasicAnimation* animation5 = [self
            setUpAnimateFromValue:@(0.4)
                          toValue:@(1.5)
                         duration:
                             [self
                                 getBufferFrameTimeDurationWithStartTime:@"3:03"
                                                                endFrame:
                                                                    @"3:12"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation5 forKey:@"Scale_Animate3"];

        playTime += [self getBufferFrameTimeDurationWithStartTime:@"3:03"
                                                         endFrame:@"4:14"];

      } break;
      case 2: {
        [bgLayer setAffineTransform:CGAffineTransformMakeScale(1.5, 1.5)];
        CABasicAnimation* animation1 = [self
            setUpAnimateFromValue:@(1.5)
                          toValue:@(0.6)
                         duration:
                             [self
                                 getBufferFrameTimeDurationWithStartTime:@"4:14"
                                                                endFrame:
                                                                    @"6:03"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation1 forKey:@"Scale_Animate"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"4:14"
                                                         endFrame:@"6:03"];

        CABasicAnimation* animation2 = [self
            setUpAnimateFromValue:@(0.6)
                          toValue:@(0.8)
                         duration:
                             [self
                                 getBufferFrameTimeDurationWithStartTime:@"6:03"
                                                                endFrame:
                                                                    @"6:09"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation2 forKey:@"Scale_Animate1"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"6:03"
                                                         endFrame:@"6:09"];

        CABasicAnimation* animation3 = [self
            setUpAnimateFromValue:@(0.8)
                          toValue:@(0.6)
                         duration:
                             [self
                                 getBufferFrameTimeDurationWithStartTime:@"6:09"
                                                                endFrame:
                                                                    @"6:15"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation3 forKey:@"Scale_Animate2"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"6:09"
                                                         endFrame:@"6:15"];

        CABasicAnimation* animation4 = [self
            setUpAnimateFromValue:@(0.6)
                          toValue:@(1.5)
                         duration:
                             [self
                                 getBufferFrameTimeDurationWithStartTime:@"6:15"
                                                                endFrame:
                                                                    @"7:11"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation4 forKey:@"Scale_Animate3"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"6:15"
                                                         endFrame:@"7:18"];

      }

      break;
      case 3: {
        [bgLayer setAffineTransform:CGAffineTransformMakeScale(0.7, 0.7)];
        [bgLayer setAffineTransform:CGAffineTransformMakeRotation(-M_PI_4 / 2)];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"7:18"
                                                         endFrame:@"8:15"];

        CABasicAnimation* animation = [self
            setUpAnimateFromValue:@(0.7)
                          toValue:@(0.5)
                         duration:
                             [self
                                 getBufferFrameTimeDurationWithStartTime:@"8:15"
                                                                endFrame:
                                                                    @"8:23"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation forKey:@"Scale_Animate"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"8:15"
                                                         endFrame:@"8:23"];

        CABasicAnimation* animation1 = [self
            setUpAnimateFromValue:@(0.5)
                          toValue:@(0.7)
                         duration:
                             [self
                                 getBufferFrameTimeDurationWithStartTime:@"8:23"
                                                                endFrame:
                                                                    @"9:09"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation1 forKey:@"Scale_Animate1"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"8:23"
                                                         endFrame:@"9:09"];

        CABasicAnimation* animation2 = [self
            setUpAnimateFromValue:@(0.7)
                          toValue:@(0.5)
                         duration:
                             [self
                                 getBufferFrameTimeDurationWithStartTime:@"9:09"
                                                                endFrame:
                                                                    @"9:13"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation2 forKey:@"Scale_Animate2"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"9:09"
                                                         endFrame:@"9:13"];

        CABasicAnimation* animation3 = [self
            setUpAnimateFromValue:@(0.5)
                          toValue:@(1.5)
                         duration:
                             [self
                                 getBufferFrameTimeDurationWithStartTime:@"9:13"
                                                                endFrame:
                                                                    @"10:06"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation3 forKey:@"Scale_Animate3"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"9:13"
                                                         endFrame:@"10:18"];

        CABasicAnimation* animation4 = [self
            setUpAnimateFromValue:@(1.5)
                          toValue:@(6)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"10:18"
                                                                  endFrame:
                                                                      @"11:03"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation4 forKey:@"Scale_Animate4"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"10:18"
                                                         endFrame:@"11:03"];

      }

      break;
      case 4: {
        [bgLayer setAffineTransform:CGAffineTransformMakeScale(6, 6)];
        [bgLayer setAffineTransform:CGAffineTransformMakeRotation(M_PI_4 / 2)];
        CABasicAnimation* animation = [self
            setUpAnimateFromValue:@(6)
                          toValue:@(0.6)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"11:03"
                                                                  endFrame:
                                                                      @"11:15"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation forKey:@"Scale_Animate"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"11:03"
                                                         endFrame:@"11:15"];

        CABasicAnimation* animation1 = [self
            setUpAnimateFromValue:@(0.6)
                          toValue:@(0.8)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"11:15"
                                                                  endFrame:
                                                                      @"11:19"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation1 forKey:@"Scale_Animate1"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"11:15"
                                                         endFrame:@"11:19"];

        CABasicAnimation* animation2 = [self
            setUpAnimateFromValue:@(0.8)
                          toValue:@(0.6)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"11:19"
                                                                  endFrame:
                                                                      @"11:23"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation2 forKey:@"Scale_Animate2"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"11:19"
                                                         endFrame:@"11:23"];

        CABasicAnimation* animation3 = [self
            setUpAnimateFromValue:@(0.6)
                          toValue:@(2.0)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"11:23"
                                                                  endFrame:
                                                                      @"12:05"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation3 forKey:@"Scale_Animate3"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"11:23"
                                                         endFrame:@"13:18"];
        CABasicAnimation* animation4 = [self
            setUpAnimateFromValue:@(2.0)
                          toValue:@(6.0)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"13:18"
                                                                  endFrame:
                                                                      @"14:05"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation4 forKey:@"Scale_Animate4"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"13:18"
                                                         endFrame:@"14:05"];

      }

      break;
      case 5: {
        [bgLayer setAffineTransform:CGAffineTransformMakeScale(6, 6)];

        CABasicAnimation* animation = [self
            setUpAnimateFromValue:@(6.0)
                          toValue:@(0.6)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"14:05"
                                                                  endFrame:
                                                                      @"14:15"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation forKey:@"Scale_Animate"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"14:05"
                                                         endFrame:@"14:15"];

        CABasicAnimation* animation1 = [self
            setUpAnimateFromValue:@(0.6)
                          toValue:@(1.0)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"14:15"
                                                                  endFrame:
                                                                      @"14:18"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation1 forKey:@"Scale_Animate1"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"14:15"
                                                         endFrame:@"14:18"];
        CABasicAnimation* animation2 = [self
            setUpAnimateFromValue:@(1.0)
                          toValue:@(0.6)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"14:18"
                                                                  endFrame:
                                                                      @"14:22"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation2 forKey:@"Scale_Animate2"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"14:18"
                                                         endFrame:@"14:22"];

        CABasicAnimation* animation3 = [self
            setUpAnimateFromValue:@(0.6)
                          toValue:@(1.5)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"14:22"
                                                                  endFrame:
                                                                      @"15:02"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation3 forKey:@"Scale_Animate3"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"14:22"
                                                         endFrame:@"16:12"];

        CABasicAnimation* animation4 = [self
            setUpAnimateFromValue:@(1.5)
                          toValue:@(6.0)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"16:12"
                                                                  endFrame:
                                                                      @"16:22"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation4 forKey:@"Scale_Animate4"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"16:12"
                                                         endFrame:@"16:22"];

      } break;
      case 6: {
        [bgLayer setAffineTransform:CGAffineTransformMakeScale(6, 6)];
        [bgLayer setAffineTransform:CGAffineTransformMakeRotation(-M_PI_4 / 2)];
        CABasicAnimation* animation = [self
            setUpAnimateFromValue:@(6.0)
                          toValue:@(0.6)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"16:22"
                                                                  endFrame:
                                                                      @"17:14"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation forKey:@"Scale_Animate"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"16:22"
                                                         endFrame:@"17:14"];

        CABasicAnimation* animation1 = [self
            setUpAnimateFromValue:@(0.6)
                          toValue:@(1.0)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"17:14"
                                                                  endFrame:
                                                                      @"17:19"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation1 forKey:@"Scale_Animate1"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"17:14"
                                                         endFrame:@"17:19"];
        CABasicAnimation* animation2 = [self
            setUpAnimateFromValue:@(1.0)
                          toValue:@(0.6)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"17:19"
                                                                  endFrame:
                                                                      @"17:22"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation2 forKey:@"Scale_Animate2"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"17:19"
                                                         endFrame:@"17:22"];

        CABasicAnimation* animation3 = [self
            setUpAnimateFromValue:@(0.6)
                          toValue:@(1.5)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"17:22"
                                                                  endFrame:
                                                                      @"18:03"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation3 forKey:@"Scale_Animate3"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"17:22"
                                                         endFrame:@"18:16"];

        CABasicAnimation* animation4 = [self
            setUpAnimateFromValue:@(1.5)
                          toValue:@(6.0)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"18:16"
                                                                  endFrame:
                                                                      @"19:00"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation4 forKey:@"Scale_Animate4"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"18:16"
                                                         endFrame:@"19:00"];

      } break;
      case 7: {
        [bgLayer setAffineTransform:CGAffineTransformMakeScale(6, 6)];
        [bgLayer setAffineTransform:CGAffineTransformMakeRotation(M_PI_4 / 2)];
        CABasicAnimation* animation = [self
            setUpAnimateFromValue:@(6.0)
                          toValue:@(0.6)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"19:00"
                                                                  endFrame:
                                                                      @"19:11"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation forKey:@"Scale_Animate"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"19:00"
                                                         endFrame:@"19:11"];

        CABasicAnimation* animation1 = [self
            setUpAnimateFromValue:@(0.6)
                          toValue:@(1.0)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"19:11"
                                                                  endFrame:
                                                                      @"19:20"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation1 forKey:@"Scale_Animate1"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"19:11"
                                                         endFrame:@"19:20"];
        CABasicAnimation* animation2 = [self
            setUpAnimateFromValue:@(1.0)
                          toValue:@(0.6)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"19:20"
                                                                  endFrame:
                                                                      @"19:22"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation2 forKey:@"Scale_Animate2"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"19:20"
                                                         endFrame:@"19:22"];

        CABasicAnimation* animation3 = [self
            setUpAnimateFromValue:@(0.6)
                          toValue:@(1.5)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"19:22"
                                                                  endFrame:
                                                                      @"20:04"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation3 forKey:@"Scale_Animate3"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"19:22"
                                                         endFrame:@"20:08"];

        CABasicAnimation* animation4 = [self
            setUpAnimateFromValue:@(1.5)
                          toValue:@(6.0)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"20:08"
                                                                  endFrame:
                                                                      @"21:14"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation4 forKey:@"Scale_Animate4"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"20:08"
                                                         endFrame:@"21:14"];

      } break;
      case 8: {
        [bgLayer setAffineTransform:CGAffineTransformMakeScale(6, 6)];
        [bgLayer setAffineTransform:CGAffineTransformMakeRotation(-M_PI_4 / 2)];
        CABasicAnimation* animation = [self
            setUpAnimateFromValue:@(6.0)
                          toValue:@(0.6)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"21:14"
                                                                  endFrame:
                                                                      @"22:00"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation forKey:@"Scale_Animate"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"21:14"
                                                         endFrame:@"22:00"];

        CABasicAnimation* animation1 = [self
            setUpAnimateFromValue:@(0.6)
                          toValue:@(1.0)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"22:00"
                                                                  endFrame:
                                                                      @"22:13"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation1 forKey:@"Scale_Animate1"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"22:00"
                                                         endFrame:@"22:13"];
        CABasicAnimation* animation2 = [self
            setUpAnimateFromValue:@(1.0)
                          toValue:@(0.6)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"22:13"
                                                                  endFrame:
                                                                      @"22:18"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation2 forKey:@"Scale_Animate2"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"22:13"
                                                         endFrame:@"22:18"];

        CABasicAnimation* animation3 = [self
            setUpAnimateFromValue:@(0.6)
                          toValue:@(1.5)
                         duration:
                             [self getBufferFrameTimeDurationWithStartTime:
                                       @"22:18"
                                                                  endFrame:
                                                                      @"22:23"]
                       animateKey:Scale_Animate
                        beginTime:playTime];
        [bgLayer addAnimation:animation3 forKey:@"Scale_Animate3"];
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"22:18"
                                                         endFrame:@"24:07"];
      } break;
      case 9:
        playTime += [self getBufferFrameTimeDurationWithStartTime:@"24:07"
                                                         endFrame:@"26:07"];
        break;

      default:
        break;
    }

    CABasicAnimation* hideAnimation =
        [self setUpOpacityAnimateFromValue:1.0 toValue:0.0 duration:0];
    hideAnimation.beginTime = playTime;
    [bgLayer addAnimation:hideAnimation forKey:@"opacityHide"];
    [parentLayer addSublayer:bgLayer];
  }
  // 草gif 动画
  NSString* filePath =
      [[NSBundle mainBundle] pathForResource:@"cao" ofType:@"gif"];
  CALayer* caoLayer = [self
      setUpGifImageLayerWithFilePath:filePath
                           videoSize:CGRectMake(0, 0, size.width, size.height)
                       startPlatTime:AVCoreAnimationBeginTimeAtZero
                            duration:0.52];
  [caoLayer removeAnimationForKey:@"gifRemove"];
  [parentLayer addSublayer:caoLayer];

  // 太阳gif 动画
  NSString* sunFilePath =
      [[NSBundle mainBundle] pathForResource:@"sunny" ofType:@"gif"];
  CALayer* sunLayer =
      [self setUpGifImageLayerWithFilePath:sunFilePath
                                 videoSize:CGRectMake(80, 1152, 590, 172)
                             startPlatTime:AVCoreAnimationBeginTimeAtZero
                                  duration:0.52];
  [sunLayer removeAnimationForKey:@"gifRemove"];
  [parentLayer addSublayer:sunLayer];

  composition.animationTool = [AVVideoCompositionCoreAnimationTool
      videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
                                                              inLayer:
                                                                  parentLayer];
}
//- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition*)composition
//                                  size:(CGSize)size {
//  NSMutableArray* origionalImages = [NSMutableArray arrayWithCapacity:0];
//  NSMutableArray* blureImages = [NSMutableArray arrayWithCapacity:0];
//  for (NSInteger i = 1; i < 11; i++) {
//    NSString* imageName = [NSString stringWithFormat:@"videoImage%@.jpg", @(i)];
//    UIImage* origionalImage = [UIImage imageNamed:imageName];
//    [origionalImages addObject:origionalImage];
//    UIImage* blureImage = [self createBlurImage:origionalImage];
//    [blureImages addObject:blureImage];
//  }
//  // 初始化视频layer
//  CALayer* parentLayer = [CALayer layer];
//  CALayer* videoLayer = [CALayer layer];
//  parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
//  videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
//  [parentLayer addSublayer:videoLayer];
//
//  CGFloat playTime = AVCoreAnimationBeginTimeAtZero;
//
//  for (int i = 0; i < 9; i++) {
//    UIImage* origionalImage = origionalImages[i];
//    if (!origionalImage) {
//      continue;
//    }
//    CGRect imageLayerFrame =
//        [self caculateImageRatioSize:origionalImage videoSize:size];
//    UIImage* blureImage = [self createBlurImage:origionalImage];
//    CALayer* blureLayer = [CALayer layer];
//    [blureLayer setContents:(id)[blureImage CGImage]];
//    blureLayer.frame = imageLayerFrame;
//    [blureLayer setAffineTransform:CGAffineTransformMakeScale(2.0, 2.0)];
//    blureLayer.opacity = 0.0;
//    CALayer* imageLayer = [CALayer layer];
//    [imageLayer setContents:(id)[origionalImage CGImage]];
//    imageLayer.frame = imageLayerFrame;
//    imageLayer.opacity = 0.0;
//    // 出现动画
//    CABasicAnimation* showAnimation =
//        [self setUpOpacityAnimateFromValue:0.0 toValue:1.0 duration:0];
//    showAnimation.beginTime = playTime;
//    [imageLayer addAnimation:showAnimation forKey:@"opacityShow"];
//    [blureLayer addAnimation:showAnimation forKey:@"opacityShow"];
//    CALayer* tipLayer = [CALayer layer];
//    switch (i) {
//      case 0: {
//        // 1
//        UIImage* firstImage = [UIImage imageNamed:@"faxian"];
//        CGRect tipFrame = CGRectMake((size.width - firstImage.size.width) / 2,
//                                     size.height / 3, firstImage.size.width,
//                                     firstImage.size.height);
//        tipLayer.frame = tipFrame;
//        [tipLayer setContents:(id)[firstImage CGImage]];
//        tipLayer.opacity = 1.0;
//        CABasicAnimation* hideAnimation =
//            [self setUpOpacityAnimateFromValue:1.0 toValue:0.0 duration:0];
//        hideAnimation.beginTime = AVCoreAnimationBeginTimeAtZero + 0.5;
//        [tipLayer addAnimation:hideAnimation forKey:@"opacityHide"];
//        [imageLayer addSublayer:tipLayer];
//        // 2
//        UIImage* secondImage = [UIImage imageNamed:@"faxian1"];
//        CALayer* chageLayer = [CALayer layer];
//        chageLayer.frame = tipFrame;
//        chageLayer.opacity = 0.0;
//        [chageLayer setContents:(id)[secondImage CGImage]];
//        playTime += [self getBufferFrameTimeDurationWithStartTime:@"0:00"
//                                                         endFrame:@"2:03"];
//
//        CABasicAnimation* showAnimation1 =
//            [self setUpOpacityAnimateFromValue:0.0 toValue:1.0 duration:0];
//        showAnimation1.beginTime = AVCoreAnimationBeginTimeAtZero + 0.5;
//        [chageLayer addAnimation:showAnimation1 forKey:@"opacityShow"];
//        [imageLayer addSublayer:chageLayer];
//
//        [parentLayer addSublayer:blureLayer];
//      }
//
//      break;
//      case 1: {
//        UIImage* firstImage = [UIImage imageNamed:@"ganjue"];
//        CGRect tipFrame = CGRectMake((size.width - firstImage.size.width) / 2,
//                                     size.height / 3, firstImage.size.width,
//                                     firstImage.size.height);
//        tipLayer.frame = tipFrame;
//        [tipLayer setContents:(id)[firstImage CGImage]];
//        tipLayer.opacity = 1.0;
//        [imageLayer addSublayer:tipLayer];
//        playTime += [self getBufferFrameTimeDurationWithStartTime:@"3:17"
//                                                         endFrame:@"4:11"];
//        [parentLayer addSublayer:blureLayer];
//      } break;
//      case 2: {
//        UIImage* firstImage = [UIImage imageNamed:@"kuailaikankan"];
//        CGRect tipFrame = CGRectMake((size.width - firstImage.size.width) / 2,
//                                     size.height / 3, firstImage.size.width,
//                                     firstImage.size.height);
//        tipLayer.frame = tipFrame;
//        [tipLayer setContents:(id)[firstImage CGImage]];
//        tipLayer.opacity = 1.0;
//        [imageLayer addSublayer:tipLayer];
//        playTime += [self getBufferFrameTimeDurationWithStartTime:@"4:11"
//                                                         endFrame:@"5:06"];
//        [parentLayer addSublayer:blureLayer];
//      }
//
//      break;
//      case 3: {
//        UIImage* firstImage = [UIImage imageNamed:@"ganjin"];
//        CGRect tipFrame = CGRectMake((size.width - firstImage.size.width) / 2,
//                                     size.height / 3, firstImage.size.width,
//                                     firstImage.size.height);
//        tipLayer.frame = tipFrame;
//        [tipLayer setContents:(id)[firstImage CGImage]];
//        tipLayer.opacity = 1.0;
//        [imageLayer addSublayer:tipLayer];
//        playTime += [self getBufferFrameTimeDurationWithStartTime:@"5:06"
//                                                         endFrame:@"6:00"];
//        [parentLayer addSublayer:blureLayer];
//      }
//
//      break;
//      case 4: {
//        UIImage* firstImage = [UIImage imageNamed:@"toutou"];
//        CGRect tipFrame = CGRectMake((size.width - firstImage.size.width) / 2,
//                                     size.height / 3, firstImage.size.width,
//                                     firstImage.size.height);
//        tipLayer.frame = tipFrame;
//        [tipLayer setContents:(id)[firstImage CGImage]];
//        tipLayer.opacity = 1.0;
//        [imageLayer addSublayer:tipLayer];
//        playTime += [self getBufferFrameTimeDurationWithStartTime:@"6:00"
//                                                         endFrame:@"6:19"];
//        [parentLayer addSublayer:blureLayer];
//      }
//
//      break;
//      case 5:
//        playTime += [self getBufferFrameTimeDurationWithStartTime:@"6:19"
//                                                         endFrame:@"7:13"];
//        [parentLayer addSublayer:blureLayer];
//        break;
//      case 6:
//        playTime += [self getBufferFrameTimeDurationWithStartTime:@"7:13"
//                                                         endFrame:@"8:09"];
//        [parentLayer addSublayer:blureLayer];
//        break;
//      case 7:
//        playTime += [self getBufferFrameTimeDurationWithStartTime:@"8:09"
//                                                         endFrame:@"9:04"];
//        [parentLayer addSublayer:blureLayer];
//        break;
//      case 8:
//        playTime += [self getBufferFrameTimeDurationWithStartTime:@"9:04"
//                                                         endFrame:@"9:23"];
//        [parentLayer addSublayer:blureLayer];
//        break;
//      case 9:
//        playTime += [self getBufferFrameTimeDurationWithStartTime:@"9:23"
//                                                         endFrame:@"12:02"];
//        break;
//
//      default:
//        break;
//    }
//    CABasicAnimation* hideAnimation =
//        [self setUpOpacityAnimateFromValue:1.0 toValue:0.0 duration:0];
//    hideAnimation.beginTime = playTime;
//    [imageLayer addAnimation:hideAnimation forKey:@"opacityHide"];
//    [blureLayer addAnimation:hideAnimation forKey:@"opacityHide"];
//    if (i == 0) {
//      playTime += [self getBufferFrameTimeDurationWithStartTime:@"2:03"
//                                                       endFrame:@"3:17"];
//    }
//    [parentLayer addSublayer:imageLayer];
//  }
//  for (int i = 1; i < 3; i++) {
//    UIImage* image =
//        [UIImage imageNamed:[NSString stringWithFormat:@"xuLie%d", i]];
//    CALayer* imageLayer = [CALayer layer];
//    [imageLayer setContents:(id)[image CGImage]];
//    imageLayer.frame = CGRectMake(0, 0, size.width, size.height);
//    imageLayer.opacity = 0.0;
//    // 出现动画
//    CABasicAnimation* showAnimation =
//        [self setUpOpacityAnimateFromValue:0.0 toValue:1.0 duration:0];
//    showAnimation.beginTime = (i == 1) ? [self getBufferFrameToTime:@"2:03"]
//                                       : [self getBufferFrameToTime:@"2:23"];
//    [imageLayer addAnimation:showAnimation forKey:@"opacityShow"];
//    CABasicAnimation* hideAnimation =
//        [self setUpOpacityAnimateFromValue:1.0 toValue:0.0 duration:0];
//    hideAnimation.beginTime = (i == 1) ? [self getBufferFrameToTime:@"2:23"]
//                                       : [self getBufferFrameToTime:@"3:17"];
//    [imageLayer addAnimation:hideAnimation forKey:@"opacityHide"];
//    [parentLayer addSublayer:imageLayer];
//  }
//  composition.animationTool = [AVVideoCompositionCoreAnimationTool
//      videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
//                                                              inLayer:
//                                                                  parentLayer];
//}
- (double)getBufferFrameTimeDurationWithStartTime:(NSString*)startFrame
                                         endFrame:(NSString*)endFrame {
  if (!startFrame || !endFrame) {
    return 0.0;
  }
  double timeDuration = 0.0;

  NSArray* startArr = [startFrame componentsSeparatedByString:@":"];
  NSArray* endArr = [endFrame componentsSeparatedByString:@":"];

  if (startArr.count == 2 && endArr.count == 2) {
    double firstStartTime = [startArr.firstObject doubleValue];
    double SecondStartTime = [endArr.firstObject doubleValue];

    double firstEndTime = [startArr.lastObject doubleValue];
    double SecondEndTime = [endArr.lastObject doubleValue];

    double startTime = firstStartTime * 25 + firstEndTime;
    double endTime = SecondStartTime * 25 + SecondEndTime;
    if (startTime > endTime) {
      return 0;
    }
    timeDuration = (endTime - startTime) / 25;
  }

  return timeDuration;
}
- (double)getBufferFrameToTime:(NSString*)bufferFrame {
  if (!bufferFrame) {
    return 0.0;
  }
  NSArray* timeArr = [bufferFrame componentsSeparatedByString:@":"];
  if (timeArr.count != 2) {
    return 0.0;
  }
  double firstStartTime = [timeArr.firstObject doubleValue];
  double SecondStartTime = [timeArr.lastObject doubleValue];

  double timeDuration = (firstStartTime * 25 + SecondStartTime) / 25;

  return timeDuration;
}
// 另外一种动画 可以打开试试
//- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition*)composition
//                                  size:(CGSize)size {
//  NSMutableArray* origionalImages = [NSMutableArray arrayWithCapacity:0];
//  NSMutableArray* blureImages = [NSMutableArray arrayWithCapacity:0];
//  for (NSInteger i = 1; i < 11; i++) {
//    NSString* imageName = [NSString stringWithFormat:@"videoImage%@.jpg", @(i)];
//    UIImage* origionalImage = [UIImage imageNamed:imageName];
//    [origionalImages addObject:origionalImage];
//    UIImage* blureImage = [self createBlurImage:origionalImage];
//    [blureImages addObject:blureImage];
//  }
//
//  // 初始化视频layer
//  CALayer* parentLayer = [CALayer layer];
//  CALayer* videoLayer = [CALayer layer];
//  parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
//  videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
//  [parentLayer addSublayer:videoLayer];
//
//  CGFloat playTime = AVCoreAnimationBeginTimeAtZero;
//  //   起始动画
//  NSString* filePath =
//      [[NSBundle mainBundle] pathForResource:@"videoBaiDu" ofType:@"gif"];
//  CALayer* imageLayer = [self
//      setUpGifImageLayerWithFilePath:filePath
//                           videoSize:CGRectMake(0, 0, size.width, size.height)
//                       startPlatTime:playTime
//                            duration:2.18];
//  if (imageLayer) {
//    playTime += 2.18;
//    [parentLayer addSublayer:imageLayer];
//  }
//  for (int i = 0; i < 9; i++) {
//    UIImage* origionalImage = origionalImages[i];
//    if (!origionalImage) {
//      continue;
//    }
//    CGRect imageLayerFrame =
//        [self caculateImageRatioSize:origionalImage videoSize:size];
//    UIImage* blureImage = [self createBlurImage:origionalImage];
//    CALayer* blureLayer = [CALayer layer];
//    [blureLayer setContents:(id)[blureImage CGImage]];
//    blureLayer.frame = imageLayerFrame;
//    [blureLayer setAffineTransform:CGAffineTransformMakeScale(2.0, 2.0)];
//    blureLayer.opacity = 0.0;
//    CALayer* imageLayer = [CALayer layer];
//    [imageLayer setContents:(id)[origionalImage CGImage]];
//    imageLayer.frame = imageLayerFrame;
//    imageLayer.opacity = 0.0;
//    // 出现动画
//    CABasicAnimation* showAnimation =
//        [self setUpOpacityAnimateFromValue:0.0 toValue:1.0 duration:0];
//    showAnimation.beginTime = playTime;
//    [imageLayer addAnimation:showAnimation forKey:@"opacityShow"];
//    [blureLayer addAnimation:showAnimation forKey:@"opacityShow"];
//    switch (i) {
//      case 0: {
//        [imageLayer setAffineTransform:CGAffineTransformMakeRotation(-M_PI_4)];
//        CABasicAnimation* animation1 =
//            [self setUpAnimateFromValue:@(-M_PI_4)
//                                toValue:@(0)
//                               duration:0.85
//                             animateKey:RotationZ_Animate
//                              beginTime:playTime];
//        [imageLayer addAnimation:animation1 forKey:@"RotationZ_Animate"];
//        playTime += 1.02;
//        [parentLayer addSublayer:blureLayer];
//      } break;
//      case 1: {
//        [imageLayer setAffineTransform:CGAffineTransformMakeTranslation(
//                                           imageLayer.frame.size.width / 2, 0)];
//
//        CABasicAnimation* animation1 =
//            [self setUpAnimateFromValue:@(imageLayer.frame.size.width / 2)
//                                toValue:@(0)
//                               duration:0.83
//                             animateKey:TranslationX_Animate
//                              beginTime:playTime];
//        [imageLayer addAnimation:animation1 forKey:@"TranslationX_Animate"];
//        [parentLayer addSublayer:blureLayer];
//        playTime += 1.87;
//      } break;
//      case 2: {
//        int animateIndex = 0;
//        NSArray* fisrtArr = @[ @(0.94), @(0.03) ];
//        NSArray* secondArr = @[ @(0.96), @(0.08) ];
//        for (int i = 1; i < 3; i++) {
//          NSArray* durationArr = (i == 1) ? fisrtArr : secondArr;
//          animateIndex++;
//          CABasicAnimation* animation1 =
//              [self setUpAnimateFromValue:@(1)
//                                  toValue:@(0.3)
//                                 duration:[durationArr[0] doubleValue]
//                               animateKey:Opacity_Animate
//                                beginTime:playTime];
//          [imageLayer
//              addAnimation:animation1
//                    forKey:[NSString stringWithFormat:@"Opacity_Animate%d",
//                                                      animateIndex]];
//          playTime += [durationArr[0] doubleValue];
//          animateIndex++;
//          CABasicAnimation* animation2 =
//              [self setUpAnimateFromValue:@(0.3)
//                                  toValue:@(1.0)
//                                 duration:[durationArr[1] doubleValue]
//                               animateKey:Opacity_Animate
//                                beginTime:playTime];
//          [imageLayer
//              addAnimation:animation2
//                    forKey:[NSString stringWithFormat:@"Opacity_Animate%d",
//                                                      animateIndex]];
//          playTime += [durationArr[1] doubleValue];
//          [parentLayer addSublayer:blureLayer];
//        }
//      }
//        playTime += 0.05;
//        break;
//      case 3: {
//        [imageLayer setAffineTransform:CGAffineTransformMakeScale(0.7, 0.7)];
//        CABasicAnimation* animation1 = [self setUpAnimateFromValue:@(0.7)
//                                                           toValue:@(1.0)
//                                                          duration:0.98
//                                                        animateKey:Scale_Animate
//                                                         beginTime:playTime];
//        [imageLayer addAnimation:animation1 forKey:@"Scale_Animate"];
//        playTime += 1.04;
//        [parentLayer addSublayer:blureLayer];
//      }
//
//      break;
//      case 4: {
//        [imageLayer setAffineTransform:CGAffineTransformMakeTranslation(
//                                           imageLayer.frame.size.width / 2,
//                                           -imageLayer.frame.size.height / 2)];
//        CABasicAnimation* animation1 = [self
//            setUpAnimateFromValue:[NSValue valueWithCGPoint:imageLayer.position]
//                          toValue:[NSValue
//                                      valueWithCGPoint:CGPointMake(
//                                                           0,
//                                                           size.height -
//                                                               imageLayerFrame
//                                                                   .origin.y)]
//                         duration:0.45
//                       animateKey:Position_Animate
//                        beginTime:playTime];
//        [imageLayer addAnimation:animation1 forKey:@"Position_Animate"];
//        playTime += 0.45;
//        playTime += 0.14;
//        CABasicAnimation* animation2 = [self setUpAnimateFromValue:@(1.0)
//                                                           toValue:@(6.0)
//                                                          duration:0.87
//                                                        animateKey:Scale_Animate
//                                                         beginTime:playTime];
//        [imageLayer addAnimation:animation2 forKey:@"Scale_Animate"];
//        playTime += 0.87;
//
//        [parentLayer addSublayer:blureLayer];
//      }
//
//      break;
//      case 5: {
//        [imageLayer setAffineTransform:CGAffineTransformMakeScale(3.0, 3.0)];
//        CABasicAnimation* animation1 = [self setUpAnimateFromValue:@(3.0)
//                                                           toValue:@(1.0)
//                                                          duration:0.33
//                                                        animateKey:Scale_Animate
//                                                         beginTime:playTime];
//        [imageLayer addAnimation:animation1 forKey:@"Scale_Animate1"];
//        playTime += 0.33;
//        playTime += 0.84;
//        CABasicAnimation* animation2 = [self setUpAnimateFromValue:@(1.0)
//                                                           toValue:@(3.0)
//                                                          duration:0.32
//                                                        animateKey:Scale_Animate
//                                                         beginTime:playTime];
//        [imageLayer addAnimation:animation2 forKey:@"Scale_Animate2"];
//        playTime += 0.32;
//        [parentLayer addSublayer:blureLayer];
//      } break;
//      case 6: {
//        [imageLayer setAffineTransform:CGAffineTransformMakeScale(6.0, 6.0)];
//        CABasicAnimation* animation1 = [self setUpAnimateFromValue:@(6.0)
//                                                           toValue:@(1.0)
//                                                          duration:0.88
//                                                        animateKey:Scale_Animate
//                                                         beginTime:playTime];
//        [imageLayer addAnimation:animation1 forKey:@"Scale_Animate1"];
//        playTime += 3.04;
//        [parentLayer addSublayer:blureLayer];
//      }
//
//      break;
//      case 7: {
//        playTime += 3.97;
//        [parentLayer addSublayer:blureLayer];
//      }
//
//      break;
//      case 8: {
//        playTime += 2.03;
//        [parentLayer addSublayer:blureLayer];
//      }
//      case 9: {
//        playTime += 4.83;
//      } break;
//      default:
//        break;
//    }
//    CABasicAnimation* hideAnimation =
//        [self setUpOpacityAnimateFromValue:1.0 toValue:0.0 duration:0];
//    hideAnimation.beginTime = playTime;
//    [imageLayer addAnimation:hideAnimation forKey:@"opacityHide"];
//    [blureLayer addAnimation:hideAnimation forKey:@"opacityHide"];
//
//    [parentLayer addSublayer:imageLayer];
//  }
//    // 生成弹幕
//    for (int i = 1; i < 6; i++) {
//      UIImage* image =
//          [UIImage imageNamed:[NSString stringWithFormat:@"danmu%d.png", i]];
//      CALayer* danmuLayer =
//          [self getDanMuLayerAboutContent:image videoSize:size danmuIndex:i];
//      [parentLayer addSublayer:danmuLayer];
//    }
//  // 生成特效
//  // 纸鹤
//  NSArray* texiaoNameArray = @[
//    @"zhiHe_", @"HuaBan_", @"love_", @"star_", @"notes_", /* @"HuDie_",
//    @"caihong_"*/
//  ];
//  NSArray* texiaoStartTimeArr =
//      @[ @(2.19), @(5.05), @(6.18), @(2.19), @(7.22), @(12.08), @(19.21) ];
//  NSArray* texiaoDurationArr =
//      @[ @(3.20), @(1.13), @(1.04), @(2.86), @(4.86), @(7.04), @(3.83) ];
//  NSArray* texiaoNumberArr =
//      @[ @(82), @(15), @(16), @(75), @(38), @(126), @(16) ];
//  for (int i = 0; i < texiaoNameArray.count; i++) {
//    NSString* name = texiaoNameArray[i];
//    NSNumber* number = texiaoNumberArr[i];
//    NSNumber* duration = texiaoDurationArr[i];
//    NSNumber* startTime = texiaoStartTimeArr[i];
//    NSArray* zhiHeArray =
//        [self createVideoTeXiaoArrayWithName:name count:[number intValue]];
//    UIImage* firstImage = zhiHeArray.firstObject;
//    CGRect frame = CGRectZero;
//    switch (i) {
//      case 0:
//        frame = CGRectMake(0, firstImage.size.height, size.width,
//                           firstImage.size.height);
//        break;
//      case 1:
//        frame = CGRectMake(0, 0, size.width, size.height);
//        break;
//      case 2:
//        frame = CGRectMake(0, 0, size.width, size.height);
//        break;
//      case 3:
//        frame = CGRectMake(0, 0, size.width, size.height);
//        break;
//      case 4:
//        frame = CGRectMake(0, 0, size.width, size.height);
//        break;
//      case 5:
//        frame = CGRectMake(0, firstImage.size.height, size.width,
//                           firstImage.size.height);
//        break;
//      case 6:
//        frame = CGRectMake((size.width - firstImage.size.width) / 2,
//                           size.height, size.width, size.height);
//        break;
//      default:
//        break;
//    }
//    CALayer* zhiHeLayer =
//        [self setUpGifImageLayerWithGifImage:zhiHeArray
//                                   videoSize:frame
//                               startPlatTime:[startTime doubleValue]
//                                    duration:[duration doubleValue]];
//    [parentLayer addSublayer:zhiHeLayer];
//  }
//  composition.animationTool = [AVVideoCompositionCoreAnimationTool
//      videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
//                                                              inLayer:
//                                                                  parentLayer];
//}
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
- (CALayer*)setUpGifImageLayerNoAnimateWithGifImage:(NSArray*)gifImageArray
                                          videoSize:(CGRect)videoSize
                                      startPlatTime:(double)startPlatTime
                                           duration:(double)duration
                                        repeatCount:(float)repeatCount {
  if (!gifImageArray) {
    return nil;
  }
  startPlatTime += AVCoreAnimationBeginTimeAtZero;
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
  imageLayer1.opacity = 1.0;

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
  gifAnimation.duration = totalTime;
  gifAnimation.beginTime = startPlatTime;
  gifAnimation.repeatCount = repeatCount;
  gifAnimation.removedOnCompletion = NO;
  gifAnimation.fillMode = kCAFillModeForwards;
  gifAnimation.calculationMode = kCAAnimationDiscrete;

  [imageLayer1 addAnimation:gifAnimation forKey:@"gif"];

  return imageLayer1;
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
@end
