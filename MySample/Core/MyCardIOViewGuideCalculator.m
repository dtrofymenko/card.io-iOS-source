//
//  MyCardIOViewGuideCalculator.m
//  MySample
//
//  Created by Dmytro Trofymenko on 12/6/17.
//

#import "MyCardIOViewGuideCalculator.h"
#import "CardIOCGGeometry.h"

@implementation MyCardIOViewGuideCalculator

- (CGRect)guideFromUIGuide:(CGRect)UIGuide {
  CGRect videoFrame = aspectFill(self.videoSize, self.videoViewSize);
  double scale = MIN(self.videoViewSize.width / self.videoSize.width,
                     self.videoViewSize.height / self.videoSize.height);
  CGRect guide = UIGuide;
  guide.origin.x -= videoFrame.origin.x;
  guide.origin.y -= videoFrame.origin.y;
  guide.origin.x /= scale;
  guide.origin.y /= scale;
  guide.size.width /= scale;
  guide.size.height /= scale;
  return guide;
}

@end
