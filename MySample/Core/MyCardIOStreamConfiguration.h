//
//  MyCardIOStreamConfiguration.h
//  MySample
//
//  Created by Dmytro Trofymenko on 12/6/17.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CardIODetectionMode.h"

@interface MyCardIOStreamConfiguration : NSObject

@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, assign) AVCaptureSessionPreset preset;
@property (nonatomic, assign) CardIODetectionMode detectionMode;

@property (nonatomic, assign) NSInteger minNumberOfFramesScannedToDeclareUnscannable;
@property (nonatomic, assign) NSInteger minTimeIntervalForAutoFocusOnce;
@property (nonatomic, assign) float isoThatSuggestsMoreTorchlightThanWeReallyNeed;
@property (nonatomic, assign) float minimalTorchLevel;

@property (nonatomic, assign) float minLuma;
@property (nonatomic, assign) float maxLuma;

@property (nonatomic, assign) NSInteger minFallbackFocusScore;
@property (nonatomic, assign) NSInteger minNonSuckyFocusScore;

@end
