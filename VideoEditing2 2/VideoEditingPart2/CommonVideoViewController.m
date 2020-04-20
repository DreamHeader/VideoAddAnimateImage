//
//  CommonVideoViewController.m
//  VideoEditingPart2
//
//  Created by Abdul Azeem Khan on 1/24/13.
//  Copyright (c) 2013 com.datainvent. All rights reserved.
//

#import "CommonVideoViewController.h"
#import <Photos/Photos.h>
@interface CommonVideoViewController ()

@end

@implementation CommonVideoViewController
- (void)viewDidLoad {
  [super viewDidLoad];

}
- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (BOOL)startMediaBrowserFromViewController:(UIViewController*)controller
                              usingDelegate:(id)delegate {
  // 1 - Validations
  if (([UIImagePickerController
           isSourceTypeAvailable:
               UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO) ||
      (delegate == nil) || (controller == nil)) {
    return NO;
  }

  // 2 - Get image picker
  UIImagePickerController* mediaUI = [[UIImagePickerController alloc] init];
  mediaUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
  mediaUI.mediaTypes =
      [[NSArray alloc] initWithObjects:(NSString*)kUTTypeMovie, nil];
  // Hides the controls for moving & scaling pictures, or for
  // trimming movies. To instead show the controls, use YES.
  mediaUI.allowsEditing = YES;
  mediaUI.delegate = delegate;

  // 3 - Display image picker
  [controller presentViewController:mediaUI animated:YES completion:nil];
  return YES;
}

- (void)imagePickerController:(UIImagePickerController*)picker
    didFinishPickingMediaWithInfo:(NSDictionary*)info {
  // 1 - Get media type
  NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];

  // 2 - Dismiss image picker
  [self dismissViewControllerAnimated:YES completion:nil];

  // 3 - Handle video selection
  if (CFStringCompare((__bridge_retained CFStringRef)mediaType, kUTTypeMovie,
                      0) == kCFCompareEqualTo) {
    self.videoAsset = [AVAsset
        assetWithURL:[info objectForKey:UIImagePickerControllerMediaURL]];
    UIAlertView* alert =
        [[UIAlertView alloc] initWithTitle:@"Asset Loaded"
                                   message:@"Video Asset Loaded"
                                  delegate:nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
    [alert show];
  }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition*)composition
                                  size:(CGSize)size {
  // no-op - override this method in the subclass
}

- (void)videoOutput {
  // 1 - Early exit if there's no video file selected
  //  if (!self.videoAsset) {
  //    UIAlertView* alert =
  //        [[UIAlertView alloc] initWithTitle:@"Error"
  //                                   message:@"Please Load a Video Asset First"
  //                                  delegate:nil
  //                         cancelButtonTitle:@"OK"
  //                         otherButtonTitles:nil];
  //    [alert show];
  //    return;
  //  }

  NSString* localVideoUrl =
      [[NSBundle mainBundle] pathForResource:@"allVideo" ofType:@"mp4"];
  // 裁剪视频
  AVAsset* playAsset =
      [self cutVideoWithPath:localVideoUrl startTime:0 endTime:15];
  //
  //    AVAsset* playAsset =
  //         [AVURLAsset assetWithURL:[NSURL fileURLWithPath:localVideoUrl]];
  // 2 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
  AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];

  // 3 - Video track
  AVMutableCompositionTrack* videoTrack = [mixComposition
      addMutableTrackWithMediaType:AVMediaTypeVideo
                  preferredTrackID:kCMPersistentTrackID_Invalid];
  AVMutableCompositionTrack* AudioTrack = [mixComposition
      addMutableTrackWithMediaType:AVMediaTypeAudio
                  preferredTrackID:kCMPersistentTrackID_Invalid];

  [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, playAsset.duration)
                      ofTrack:[[playAsset tracksWithMediaType:AVMediaTypeVideo]
                                  objectAtIndex:0]
                       atTime:kCMTimeZero
                        error:nil];
  [AudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, playAsset.duration)
                      ofTrack:[[playAsset tracksWithMediaType:AVMediaTypeAudio]
                                  objectAtIndex:0]
                       atTime:kCMTimeZero
                        error:nil];
  // 3.1 - Create AVMutableVideoCompositionInstruction
  AVMutableVideoCompositionInstruction* mainInstruction =
      [AVMutableVideoCompositionInstruction videoCompositionInstruction];
  mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, playAsset.duration);

  // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
  AVMutableVideoCompositionLayerInstruction* videolayerInstruction =
      [AVMutableVideoCompositionLayerInstruction
          videoCompositionLayerInstructionWithAssetTrack:videoTrack];
  AVAssetTrack* videoAssetTrack =
      [[playAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
  UIImageOrientation videoAssetOrientation_ = UIImageOrientationUp;
  BOOL isVideoAssetPortrait_ = NO;
  CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
  if (videoTransform.a == 0 && videoTransform.b == 1.0 &&
      videoTransform.c == -1.0 && videoTransform.d == 0) {
    videoAssetOrientation_ = UIImageOrientationRight;
    isVideoAssetPortrait_ = YES;
  }
  if (videoTransform.a == 0 && videoTransform.b == -1.0 &&
      videoTransform.c == 1.0 && videoTransform.d == 0) {
    videoAssetOrientation_ = UIImageOrientationLeft;
    isVideoAssetPortrait_ = YES;
  }
  if (videoTransform.a == 1.0 && videoTransform.b == 0 &&
      videoTransform.c == 0 && videoTransform.d == 1.0) {
    videoAssetOrientation_ = UIImageOrientationUp;
  }
  if (videoTransform.a == -1.0 && videoTransform.b == 0 &&
      videoTransform.c == 0 && videoTransform.d == -1.0) {
    videoAssetOrientation_ = UIImageOrientationDown;
  }
  [videolayerInstruction setTransform:videoAssetTrack.preferredTransform
                               atTime:kCMTimeZero];
  [videolayerInstruction setOpacity:0.0 atTime:playAsset.duration];

  // 3.3 - Add instructions
  mainInstruction.layerInstructions =
      [NSArray arrayWithObjects:videolayerInstruction, nil];

  AVMutableVideoComposition* mainCompositionInst =
      [AVMutableVideoComposition videoComposition];

  CGSize naturalSize;
  if (isVideoAssetPortrait_) {
    naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height,
                             videoAssetTrack.naturalSize.width);
  } else {
    naturalSize = videoAssetTrack.naturalSize;
  }

  float renderWidth, renderHeight;
  renderWidth = naturalSize.width;
  renderHeight = naturalSize.height;
  mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
  mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
  mainCompositionInst.frameDuration = CMTimeMake(1, 30);

  [self applyVideoEffectsToComposition:mainCompositionInst size:naturalSize];

  // 4 - Get path
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSString* documentsDirectory = [paths objectAtIndex:0];
  NSString* myPathDocs = [documentsDirectory
      stringByAppendingPathComponent:[NSString
                                         stringWithFormat:@"FinalVideo-%d.mov",
                                                          arc4random() % 1000]];
  NSURL* url = [NSURL fileURLWithPath:myPathDocs];

  // 5 - Create exporter
  AVAssetExportSession* exporter = [[AVAssetExportSession alloc]
      initWithAsset:mixComposition
         presetName:AVAssetExportPresetHighestQuality];
  exporter.outputURL = url;
  exporter.outputFileType = AVFileTypeQuickTimeMovie;
  exporter.shouldOptimizeForNetworkUse = YES;
  exporter.videoComposition = mainCompositionInst;
  [exporter exportAsynchronouslyWithCompletionHandler:^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [self exportDidFinish:exporter];
    });
  }];
}
- (void)exportDidFinish:(AVAssetExportSession*)session {
  if (session.status == AVAssetExportSessionStatusCompleted) {
    NSURL* outputURL = session.outputURL;
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];

    if (status == PHAuthorizationStatusAuthorized) {
      PHPhotoLibrary* photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
      [photoLibrary
          performChanges:^{
            [PHAssetChangeRequest
                creationRequestForAssetFromVideoAtFileURL:outputURL];
          }
          completionHandler:^(BOOL success, NSError* _Nullable error) {
              dispatch_async(dispatch_get_main_queue(), ^{
                  NSString * message = @"已将未能保存视频到相册保存至相册";
                  if (success) {
                     message = @"已将视频保存至相册";
                  }
                  UIAlertView* alert =
                          [[UIAlertView alloc] initWithTitle:@"Error"
                                                     message:message
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
                      [alert show];
              });
           
          }];
    } else if (status == PHAuthorizationStatusDenied) {
    } else if (status == PHAuthorizationStatusNotDetermined) {
      // Access has not been determined.
      [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
        } else {
        }
      }];
    } else if (status == PHAuthorizationStatusRestricted) {
    }
  }
}
// 裁剪视频
- (AVAsset*)cutVideoWithPath:(NSString*)videoPath
                   startTime:(NSTimeInterval)start
                     endTime:(NSTimeInterval)end {
  ///更具视频路径来创建asset
  AVURLAsset* asset =
      [AVURLAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
  //1创建一个AVMutableComposition
  AVMutableComposition* composition = [[AVMutableComposition alloc] init];
  //2 创建一个音频和视频的轨道,类型都为AVMediaTypeAudio
  AVMutableCompositionTrack* muTrack =
      [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                               preferredTrackID:kCMPersistentTrackID_Invalid];

  AVMutableCompositionTrack* audioTrack =
      [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                               preferredTrackID:kCMPersistentTrackID_Invalid];

  //创建一个轨道级检查界面的对象
  AVAssetTrack* originTrack =
      [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;

  AVAssetTrack* originAudioTrack =
      [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
  ////获取videoPath的音视频插入轨道
  [muTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(
                                               start, asset.duration.timescale),
                                           CMTimeMakeWithSeconds(
                                               end, asset.duration.timescale))
                   ofTrack:originTrack
                    atTime:kCMTimeZero
                     error:nil];
  [audioTrack
      insertTimeRange:CMTimeRangeMake(
                          CMTimeMakeWithSeconds(start,
                                                asset.duration.timescale),
                          CMTimeMakeWithSeconds(end, asset.duration.timescale))
              ofTrack:originAudioTrack
               atTime:kCMTimeZero
                error:nil];

  muTrack.preferredTransform = originTrack.preferredTransform;

  return composition;
}
@end
