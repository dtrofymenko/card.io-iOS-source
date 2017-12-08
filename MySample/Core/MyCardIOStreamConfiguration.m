//
//  MyCardIOStreamConfiguration.m
//  MySample
//
//  Created by Dmytro Trofymenko on 12/6/17.
//

#import "MyCardIOStreamConfiguration.h"

@implementation MyCardIOStreamConfiguration

- (id)init {
  self = [super init];
  if (nil != self) {
    self.preset = AVCaptureSessionPresetHigh;
    self.detectionMode = CardIODetectionModeAutomatic;
    self.minNumberOfFramesScannedToDeclareUnscannable = 100;
    self.minTimeIntervalForAutoFocusOnce = 2;
    self.isoThatSuggestsMoreTorchlightThanWeReallyNeed = 250;
    self.minimalTorchLevel = 0.05f;
    
    self.minLuma = 100;
    self.maxLuma = 200;
    
    self.minFallbackFocusScore = 6;
    self.minNonSuckyFocusScore = 3;
  }
  
  return self;
}

@end
