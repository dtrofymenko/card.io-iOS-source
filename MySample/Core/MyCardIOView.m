//
//  MyCardIOView.m
//  MySample
//
//  Created by Dmytro Trofymenko on 12/6/17.
//

#import "MyCardIOView.h"
#import "MyCardIOStreamView.h"
#import "MyCardIOViewGuideCalculator.h"
#import "MyCardIOStream.h"
#import "MyCardIOStandartGuideView.h"

@interface MyCardIOView() <MyCardIOStreamDelegate>

@property (nonatomic, strong) UIView<MyCardIOGuideView> *guideView;
@property (nonatomic, strong) MyCardIOStreamView *streamView;
@property (nonatomic, assign, getter = isStarted) BOOL started;
@property (nonatomic, strong) MyCardIOViewGuideCalculator *guideCalculator;
@property (nonatomic, strong) MyCardIOStream *stream;
@property (nonatomic, assign) BOOL didComplete;

@end

@implementation MyCardIOView

- (id)initWithConfiguration:(MyCardIOConfiguration *)configuration {
    self = [self initWithFrame:[[UIScreen mainScreen] bounds]];
    [self setupWithConfiguration:configuration];
    return self;
}

- (void)start {
  if (!self.started) {
    [self layoutIfNeeded];
    self.started = true;
    [self.stream start];
    self.guideCalculator.videoSize = self.stream.videoSize;
    self.guideCalculator.videoViewSize = self.streamView.frame.size;
    self.stream.guide = [self.guideCalculator guideFromUIGuide:self.guideView.guideFrame];
    self.stream.guideOrientation = self.guideView.guideOrientation;
  }
}

- (void)stop {
  if (self.started) {
    self.didComplete = false;
    self.started = false;
    [self.stream stop];
  }
}

#pragma mark - UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  self.guideView.frame = self.bounds;
}

#pragma mark - Private

- (void)setupWithConfiguration:(MyCardIOConfiguration *)configuration {
  self.backgroundColor = [UIColor whiteColor];

  self.streamView = [[MyCardIOStreamView alloc] initWithFrame:self.bounds];
  [self addSubview:self.streamView];
  
  self.guideView = configuration.guideView;
  if (nil == self.guideView) {
    self.guideView = [[MyCardIOStandartGuideView alloc] init];
  }
  [self addSubview:self.guideView];

  self.guideCalculator = [[MyCardIOViewGuideCalculator alloc] init];
  
  self.stream = [[MyCardIOStream alloc] initWithConfiguration:configuration.streamConfiguration];
  self.streamView.session = self.stream.session;
  self.stream.delegate = self;
  [self setNeedsLayout];
}

#pragma mark - MyCardIOStreamDelegate

- (void)cardIOStream:(MyCardIOStream *)stream didProcessFrame:(MyCardIOFrameInfo *)frameInfo {
  [self.guideView updateWithFrame:frameInfo];
  if (frameInfo.completed && !self.didComplete) {
    self.didComplete = true;
    [self.delegate cardIOView:self didComplete:frameInfo.cardInfo];
  }
}

@end
