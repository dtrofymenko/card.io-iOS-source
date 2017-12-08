//
//  MyCardIOStandartGuideView.m
//  MySample
//
//  Created by Dmytro Trofymenko on 12/6/17.
//

#import "MyCardIOStandartGuideView.h"
#import "MyCardIOFrameView.h"

@interface MyCardIOStandartGuideView()

@property (nonatomic, assign) CGRect guideFrame;
@property (nonatomic, strong) MyCardIOFrameView *guideView;

@end

@implementation MyCardIOStandartGuideView

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (nil != self) {
    [self setup];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  CGRect guideFrame = CGRectZero;
  guideFrame.origin.x = 30.0;
  guideFrame.size.width = CGRectGetWidth(self.bounds) - 2 * guideFrame.origin.x;
  guideFrame.size.height = (CGFloat)ceil(guideFrame.size.width * 270.0 / 428.0);
  guideFrame.origin.y = (CGFloat)ceil(CGRectGetMidY(self.bounds) - CGRectGetHeight(guideFrame) / 2.0);
  
  self.guideFrame = guideFrame;
  self.guideView.frame = guideFrame;
}

- (UIInterfaceOrientation)guideOrientation {
  return UIInterfaceOrientationPortrait;
}

#pragma mark - MyCardIOGuideView

- (void)updateWithFrame:(MyCardIOFrameInfo *)info {
  self.guideView.frameInfo = info;
  [self setNeedsLayout];
}

#pragma mark - Private

- (void)setup {
  self.backgroundColor = [UIColor clearColor];
  self.guideView = [[MyCardIOFrameView alloc] init];
  self.guideView.lineWidth = 6.0;
  [self addSubview:self.guideView];
}

@end
