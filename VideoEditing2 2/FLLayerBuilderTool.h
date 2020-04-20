//
//  FLLayerBuilderTool.h
//  VideoEditingPart2
//
//  Created by MacHD on 2020/4/14.
//  Copyright © 2020 com.datainvent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLLayerBuilderTool : NSObject
+ (UIBezierPath*) createPathForText:(NSString*)string fontHeight:(CGFloat)height fontName:(CFStringRef)fontName;
@end

NS_ASSUME_NONNULL_END
