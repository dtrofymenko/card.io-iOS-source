//
//  MyCardIOStream.m
//  MySample
//
//  Created by Dmytro Trofymenko on 12/6/17.
//

#import "MyCardIOStream.h"
#import "dmz.h"
#import "CardIOCardScanner.h"
#import "CardIOMacros.h"
#import "CardIOVideoFrame.h"
#import "MyCardIOFrameInfo+Internal.h"
#define kRidiculouslyHighIsoSpeed 10000
#define kCoupleOfHours 10000
#define kVideoQueueName "io.card.ios.videostream"

@interface MyCardIOStream() <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, assign) CardIODetectionMode detectionMode;
@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureVideoDataOutput *output;
@property (nonatomic, strong) CardIOCardScanner *scanner;

@property (nonatomic, assign) NSInteger minNumberOfFramesScannedToDeclareUnscannable;
@property (nonatomic, assign) NSInteger minTimeIntervalForAutoFocusOnce;
@property (nonatomic, assign) float isoThatSuggestsMoreTorchlightThanWeReallyNeed;
@property (nonatomic, assign) float minimalTorchLevel;
@property (nonatomic, assign) float minLuma;
@property (nonatomic, assign) float maxLuma;
@property (nonatomic, assign) NSInteger minFallbackFocusScore;
@property (nonatomic, assign) NSInteger minNonSuckyFocusScore;

@property (nonatomic, assign, getter = isStarted) BOOL started;
@property (nonatomic, assign) CGSize videoSize;
@property (nonatomic, assign) CardIODetectionMode activeDetectionMode;
@property (nonatomic, assign, readwrite) NSTimeInterval lastAutoFocusOnceTime;
@property (nonatomic, assign, readwrite) BOOL currentlyAdjustingFocus;
@property (nonatomic, assign, readwrite) BOOL currentlyAdjustingExposure;
@property (nonatomic, assign, readwrite) NSTimeInterval lastChangeSignal;
@property (nonatomic, assign, readwrite) BOOL lastChangeTorchStateToOFF;

// This semaphore is intended to prevent a crash which was recorded with this exception message:
// "AVCaptureSession can't stopRunning between calls to beginConfiguration / commitConfiguration"
@property(nonatomic, strong, readwrite) dispatch_semaphore_t cameraConfigurationSemaphore;

#if USE_CAMERA
@property (nonatomic, assign) dmz_context *dmz;
#endif

@end

@implementation MyCardIOStream
#if USE_CAMERA
@synthesize dmz = _dmz;
#endif

- (id)initWithConfiguration:(MyCardIOStreamConfiguration *)configuration {
  self = [super init];
  if (self) {
    [self setupWithConfiguration:configuration];
  }
  return self;
}

- (void)dealloc {
#if USE_CAMERA
  dmz_context_destroy(_dmz), _dmz = NULL;
#endif
}

- (void)start {
  if (!self.started && [self addInputAndOutput]) {
    [self.session startRunning];
    self.started = true;
    
    self.scanner = [[CardIOCardScanner alloc] init];
    self.activeDetectionMode = self.detectionMode;
  }
}

- (void)stop {
  if (self.started) {
    [self.session stopRunning];
    [self removeInputAndOutput];
    self.started = false;
    
    self.scanner = nil;
    self.activeDetectionMode = self.detectionMode;
  }
}

#pragma mark - Torch

- (BOOL)hasTorch {
  return [self.device hasTorch] &&
  [self.device isTorchModeSupported:AVCaptureTorchModeOn] &&
  [self.device isTorchModeSupported:AVCaptureTorchModeOff] &&
  self.device.torchAvailable;
}

- (BOOL)canSetTorchLevel {
  return [self.device hasTorch] && [self.device respondsToSelector:@selector(setTorchModeOnWithLevel:error:)];
}

- (BOOL)torchIsOn {
  return self.device.torchMode == AVCaptureTorchModeOn;
}

- (BOOL)setTorchOn:(BOOL)torchShouldBeOn {
  return [self changeCameraConfiguration:^{
    AVCaptureTorchMode newTorchMode = torchShouldBeOn ? AVCaptureTorchModeOn : AVCaptureTorchModeOff;
    [self.device setTorchMode:newTorchMode];
  }
#if CARDIO_DEBUG
  withErrorMessage:@"CardIO couldn't lock for configuration to turn on/off torch: %@"
#endif
  ];
}

- (BOOL)setTorchModeOnWithLevel:(float)torchLevel {
  __block BOOL torchSuccess = NO;
  BOOL success = [self changeCameraConfiguration:^{
    NSError *error;
    torchSuccess = [self.device setTorchModeOnWithLevel:torchLevel error:&error];
  }
#if CARDIO_DEBUG
  withErrorMessage:@"CardIO couldn't lock for configuration to turn on/off torch with level: %@"
#endif
  ];

  return success && torchSuccess;
}


#pragma mark - Focus

- (BOOL)hasAutofocus {
  return [self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus];
}

- (void)refocus {
  CardIOLog(@"Manual refocusing");
  [self autofocusOnce];
  [self performSelector:@selector(resumeContinuousAutofocusing) withObject:nil afterDelay:0.1f];
}

- (void)autofocusOnce {
  [self changeCameraConfiguration:^{
    if([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
      [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
    }
  }
#if CARDIO_DEBUG
  withErrorMessage:@"CardIO couldn't lock for configuration to autofocusOnce: %@"
#endif
   ];
}

- (void)resumeContinuousAutofocusing {
  [self changeCameraConfiguration:^{
    if([self.device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
      [self.device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
    }
  }
#if CARDIO_DEBUG
  withErrorMessage:@"CardIO couldn't lock for configuration to resumeContinuousAutofocusing: %@"
#endif
   ];
}

#pragma mark - Private

- (void)setupWithConfiguration:(MyCardIOStreamConfiguration *)configuration {
  self.device = configuration.device;
  if (nil == self.device) {
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  }
  
  self.session = [[AVCaptureSession alloc] init];
  self.session.sessionPreset = configuration.preset;
  
  self.detectionMode = configuration.detectionMode;
  
  self.minNumberOfFramesScannedToDeclareUnscannable = configuration.minNumberOfFramesScannedToDeclareUnscannable;
  self.minTimeIntervalForAutoFocusOnce = configuration.minTimeIntervalForAutoFocusOnce;
  self.isoThatSuggestsMoreTorchlightThanWeReallyNeed = configuration.isoThatSuggestsMoreTorchlightThanWeReallyNeed;
  self.minimalTorchLevel = configuration.minimalTorchLevel;
  self.minLuma = configuration.minLuma;
  self.maxLuma = configuration.maxLuma;
  self.minFallbackFocusScore = configuration.minFallbackFocusScore;
  self.minNonSuckyFocusScore = configuration.minNonSuckyFocusScore;

  #if USE_CAMERA
  _dmz = dmz_context_create();
  #endif
  self.cameraConfigurationSemaphore = dispatch_semaphore_create(1); // parameter of `1` implies "allow access to only one thread at a time"
}

- (BOOL)addInputAndOutput {
  NSError *error = nil;
  self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
  if(error || !self.self.input) {
    CardIOLog(@"CardIO camera input error: %@", error);
    return NO;
  }
  
  [self.session addInput:self.input];
  
  self.output = [[AVCaptureVideoDataOutput alloc] init];
  NSDictionary *videoOutputSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
                                                                  forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
  [self.output setVideoSettings:videoOutputSettings];
  self.output.alwaysDiscardsLateVideoFrames = YES;
  // NB: DO NOT USE minFrameDuration. minFrameDuration causes focusing to
  // slow down dramatically, which causes significant ux pain.
  dispatch_queue_t queue = dispatch_queue_create(kVideoQueueName, NULL);
  [self.output setSampleBufferDelegate:self queue:queue];
  
  [self.session addOutput:self.output];
  //! Rotate size here
  self.videoSize = CGSizeMake([self.output.videoSettings[(NSString *)kCVPixelBufferHeightKey] floatValue],
                              [self.output.videoSettings[(NSString *)kCVPixelBufferWidthKey] floatValue]);
  
  return YES;
}

- (void)removeInputAndOutput {
  [self.session removeInput:self.input];
  [self.output setSampleBufferDelegate:nil queue:NULL];
  [self.session removeOutput:self.output];
  self.input = nil;
  self.output = nil;
}

- (BOOL)changeCameraConfiguration:(void(^)())changeBlock
#if CARDIO_DEBUG
                 withErrorMessage:(NSString *)errorMessage
#endif
{
  dispatch_semaphore_wait(self.cameraConfigurationSemaphore, DISPATCH_TIME_FOREVER);
  
  BOOL success = NO;
  NSError *lockError = nil;
  [self.session beginConfiguration];
  [self.device lockForConfiguration:&lockError];
  if(!lockError) {
    changeBlock();
    [self.device unlockForConfiguration];
    success = YES;
  }
#if CARDIO_DEBUG
  else {
    CardIOLog(errorMessage, lockError);
  }
#endif
  
  [self.session commitConfiguration];
  
  dispatch_semaphore_signal(self.cameraConfigurationSemaphore);
  
  return success;
}

- (void)sendFrameToDelegate:(CardIOVideoFrame *)frame {
  // Due to threading, we can receive frames after we've stopped running.
  // Clean this up for our delegate.
  if(self.started) {
    MyCardIOFrameInfo *frameInfo = [[MyCardIOFrameInfo alloc] initWithFrame:frame];
    [self.delegate cardIOStream:self didProcessFrame:frameInfo];
  }
  else {
    CardIOLog(@"STRAY FRAME!!! wasted processing. we are sad.");
  }
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
  if (!self.started) {
    return;
  }
  #if USE_CAMERA
  @autoreleasepool {
    CardIOVideoFrame *frame = [[CardIOVideoFrame alloc] initWithSampleBuffer:sampleBuffer
                                                        interfaceOrientation:self.guideOrientation];
    frame.scanner = self.scanner;
    frame.dmz = _dmz;
    frame.minLuma = self.minLuma;
    frame.maxLuma = self.maxLuma;
    frame.minFallbackFocusScore = self.minFallbackFocusScore;
    frame.minNonSuckyFocusScore = self.minNonSuckyFocusScore;
    //! Rotate and scale guide here
    frame.relativeGuide = CGRectMake(self.guide.origin.y / self.videoSize.height,
                                     self.guide.origin.x / self.videoSize.width,
                                     self.guide.size.height / self.videoSize.height,
                                     self.guide.size.width / self.videoSize.width);
    
    frame.detectionMode = self.detectionMode;
    
    if (!self.currentlyAdjustingFocus) {
      if ([self canSetTorchLevel]) {
        frame.calculateBrightness = YES;
        frame.torchIsOn = [self torchIsOn];
      }
      
      NSDictionary *exifDict = (__bridge NSDictionary *)((CFDictionaryRef)CMGetAttachment(sampleBuffer, (CFStringRef)@"{Exif}", NULL));
      if (exifDict != nil) {
        frame.isoSpeed = [exifDict[@"ISOSpeedRatings"][0] integerValue];
        frame.shutterSpeed = [exifDict[@"ShutterSpeedValue"] floatValue];
      }
      else {
        frame.isoSpeed = kRidiculouslyHighIsoSpeed;
        frame.shutterSpeed = 0;
      }
      
      [frame process];
      
      if (frame.cardY && self.activeDetectionMode == CardIODetectionModeAutomatic) {
        if (self.scanner.scanSessionAnalytics->num_frames_scanned > self.minNumberOfFramesScannedToDeclareUnscannable) {
          self.activeDetectionMode = CardIODetectionModeCardImageOnly;
          frame.detectionMode = CardIODetectionModeCardImageOnly;
          [frame process];
        }
      }
    }
    
    [self performSelectorOnMainThread:@selector(sendFrameToDelegate:) withObject:frame waitUntilDone:NO];
    
    // Autofocus
    BOOL didAutoFocus = NO;
    if (!self.currentlyAdjustingFocus && frame.focusSucks && [self hasAutofocus]) {
      NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
      if (now - self.lastAutoFocusOnceTime > self.minTimeIntervalForAutoFocusOnce) {
        self.lastAutoFocusOnceTime = now;
        CardIOLog(@"Auto-triggered focusing");
        [self autofocusOnce];
        [self performSelector:@selector(resumeContinuousAutofocusing) withObject:nil afterDelay:0.1f];
        didAutoFocus = YES;
      }
    }
    
    // Auto-torch
    if (!self.currentlyAdjustingFocus && !didAutoFocus && !self.currentlyAdjustingExposure && [self canSetTorchLevel]) {
      NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
      BOOL changeTorchState = NO;
      BOOL changeTorchStateToOFF = NO;
      if (frame.brightnessHigh) {
        if ([self torchIsOn]) {
          changeTorchState = YES;
          changeTorchStateToOFF = YES;
        }
      }
      else {
        if (frame.brightnessLow) {
          if (![self torchIsOn] && frame.isoSpeed > self.isoThatSuggestsMoreTorchlightThanWeReallyNeed) {
            changeTorchState = YES;
            changeTorchStateToOFF = NO;
          }
        }
        else if ([self torchIsOn]) {
          if (frame.isoSpeed < self.isoThatSuggestsMoreTorchlightThanWeReallyNeed) {
            changeTorchState = YES;
            changeTorchStateToOFF = YES;
          }
        }
      }
      
      // Require at least two consecutive change signals in the same direction, over at least one second.
      
      // Note: if self.lastChangeSignal == 0.0, then we've just entered camera view.
      // In that case, lastChangeTorchStateToOFF == NO, and so turning ON the torch won't wait that second.
      
      if (changeTorchState) {
        if (changeTorchStateToOFF == self.lastChangeTorchStateToOFF) {
          if (now - self.lastChangeSignal > 1) {
            CardIOLog(@"Automatic torch change");
            if (changeTorchStateToOFF) {
              [self setTorchOn:NO];
            }
            else {
              [self setTorchModeOnWithLevel:self.minimalTorchLevel];
            }
            self.lastChangeSignal = now + kCoupleOfHours;
          }
          else {
            self.lastChangeSignal = MIN(self.lastChangeSignal, now);
          }
        }
        else {
          self.lastChangeSignal = now;
          self.lastChangeTorchStateToOFF = changeTorchStateToOFF;
        }
      }
      else {
        self.lastChangeSignal = now + kCoupleOfHours;
      }
    }
  }
  #endif
}


@end
