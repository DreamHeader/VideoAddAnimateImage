//
//  ISGifToImageInfoTool.m
//  VideoEditingPart2
//
//  Created by MacHD on 2020/4/14.
//  Copyright © 2020 com.datainvent. All rights reserved.
//

#import "ISGifToImageInfoTool.h"
#import <CoreServices/CoreServices.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

const int32_t TGGifConverterFPS = 600;

@implementation ISGifToImageInfoTool

+ (NSDictionary *)getGifInfoWithSource:(NSData *)gifData
{
  size_t currentFrameNumber = 0;
  CGFloat totalFrameDelay = 0;

  CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)gifData, nil);
  NSMutableArray *frameinfoArray = @[].mutableCopy;
  
  while (YES) {
      NSDictionary *options = @{ (NSString *)kCGImageSourceTypeIdentifierHint : (id)kUTTypeGIF };
      CGImageRef imgRef = CGImageSourceCreateImageAtIndex(source, currentFrameNumber, (__bridge CFDictionaryRef)options);
      if (imgRef != NULL) {
          CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source, currentFrameNumber, NULL);
          CFDictionaryRef gifProperties = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
          
          if (gifProperties != NULL) {
            float frameDuration = 0.1f;
            NSNumber *delayTimeUnclampedProp = CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFUnclampedDelayTime);
            if (delayTimeUnclampedProp != nil)
            {
                frameDuration = [delayTimeUnclampedProp floatValue];
            }
            else
            {
                NSNumber *delayTimeProp = CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFDelayTime);
                if (delayTimeProp != nil)
                    frameDuration = [delayTimeProp floatValue];
            }
            
            if (frameDuration < 0.011f) frameDuration = 0.100f;
            
            [frameinfoArray addObject:@{@"image":[UIImage imageWithCGImage:imgRef], @"delay":@(frameDuration)}];
            totalFrameDelay += frameDuration;
          }
          
          if (properties) CFRelease(properties);
          CGImageRelease(imgRef);
          currentFrameNumber++;
      }
      else {
        break;
      }
  }
  CFRelease(source);
  return @{@"imageList":frameinfoArray, @"totalTime":@(totalFrameDelay)};
}

@end

