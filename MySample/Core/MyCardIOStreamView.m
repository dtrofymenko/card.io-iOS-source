//
//  MyCardIOStreamView.m
//  MySample
//
//  Created by Dmytro Trofymenko on 12/6/17.
//

#import "MyCardIOStreamView.h"

@interface MyCardIOStreamView()

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation MyCardIOStreamView

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (nil != self) {
    [self setup];
  }
  return self;
}

- (void)setSession:(AVCaptureSession *)session {
  _session = session;
  self.previewLayer.session = session;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.previewLayer.frame = self.bounds;
}

#pragma mark - Private

- (void)setup {
  self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] init];
  self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  [self.layer addSublayer:self.previewLayer];
}

@end
