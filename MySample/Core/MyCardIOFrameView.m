//
//  MyCardIOFrameView.m
//  MySample
//
//  Created by Dmytro Trofymenko on 12/8/17.
//

#import "MyCardIOFrameView.h"
#import "CardIOCGGeometry.h"

#define kStandardLineWidth 12.0f
#define kStandardCornerSize 50.0f
#define kAdjustFudge 0.2f  // Because without this, we see a mini gap between edge path and corner path.

#define kEdgeDecay 0.5f
#define kEdgeOnThreshold 0.7f
#define kEdgeOffThreshold 0.3f

#define kAllEdgesFoundScoreDecay 0.5f
#define kNumEdgesFoundScoreDecay 0.5f

#pragma mark - Types

typedef enum {
  kTopLeft,
  kTopRight,
  kBottomLeft,
  kBottomRight,
} CornerPositionType;

#pragma mark - Interface

@interface MyCardIOFrameView ()

@property(nonatomic, strong, readwrite) CAShapeLayer *topLayer;
@property(nonatomic, strong, readwrite) CAShapeLayer *bottomLayer;
@property(nonatomic, strong, readwrite) CAShapeLayer *leftLayer;
@property(nonatomic, strong, readwrite) CAShapeLayer *rightLayer;
@property(nonatomic, strong, readwrite) CAShapeLayer *topLeftLayer;
@property(nonatomic, strong, readwrite) CAShapeLayer *topRightLayer;
@property(nonatomic, strong, readwrite) CAShapeLayer *bottomLeftLayer;
@property(nonatomic, strong, readwrite) CAShapeLayer *bottomRightLayer;
@property(nonatomic, assign, readwrite) BOOL guidesLockedOn;
@property(nonatomic, assign, readwrite) float edgeScoreTop;
@property(nonatomic, assign, readwrite) float edgeScoreRight;
@property(nonatomic, assign, readwrite) float edgeScoreBottom;
@property(nonatomic, assign, readwrite) float edgeScoreLeft;
@property(nonatomic, assign, readwrite) float allEdgesFoundDecayedScore;
@property(nonatomic, assign, readwrite) float numEdgesFoundDecayedScore;

@end

@implementation MyCardIOFrameView

- (id)init {
  if(self = [super init]) {
    [self setup];
  }
  return self;
}

#pragma mark - UIView

- (void)layoutSubviews {
  [self setLayerPaths];
}

#pragma mark - Private

- (void)setup {
    _guideColor = [UIColor greenColor];
    _lineWidth = 12.0;
    _cornerSize = 50.0f;
  
    _guidesLockedOn = NO;
    _edgeScoreTop = 0.0f;
    _edgeScoreRight = 0.0f;
    _edgeScoreBottom = 0.0f;
    _edgeScoreLeft = 0.0f;

    _allEdgesFoundDecayedScore = 0.0f;
    _numEdgesFoundDecayedScore = 0.0f;

    _topLayer = [CAShapeLayer layer];
    _bottomLayer = [CAShapeLayer layer];
    _leftLayer = [CAShapeLayer layer];
    _rightLayer = [CAShapeLayer layer];
  
    _topLeftLayer = [CAShapeLayer layer];
    _topRightLayer = [CAShapeLayer layer];
    _bottomLeftLayer = [CAShapeLayer layer];
    _bottomRightLayer = [CAShapeLayer layer];
  
    NSArray *edgeLayers = [NSArray arrayWithObjects:
                           _topLayer,
                           _bottomLayer,
                           _leftLayer,
                           _rightLayer,
                           _topLeftLayer,
                           _topRightLayer,
                           _bottomLeftLayer,
                           _bottomRightLayer,
                           nil];
  
    for(CAShapeLayer *layer in edgeLayers) {
      layer.frame = CGRectZeroWithSize(self.bounds.size);
      layer.lineCap = kCALineCapButt;
      layer.lineWidth = [self lineWidth];
      layer.fillColor = [UIColor clearColor].CGColor;
      layer.strokeColor = self.guideColor.CGColor;
      
      [self.layer addSublayer:layer];
    }

    [self setNeedsLayout];
}

- (CGPoint)landscapeVEdgeAdj {
  return CGPointMake(0.0f, -([self cornerSize] - kAdjustFudge));
}

- (CGPoint)landscapeHEdgeAdj {
  return CGPointMake([self cornerSize] - kAdjustFudge, 0.0f);
}

+ (CGPathRef)newPathFromPoint:(CGPoint)firstPoint toPoint:(CGPoint)secondPoint {
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathMoveToPoint(path, NULL, firstPoint.x, firstPoint.y);
  CGPathAddLineToPoint(path, NULL, secondPoint.x, secondPoint.y);
  return path;
}

+ (CGPathRef)newCornerPathFromPoint:(CGPoint)point size:(CGFloat)size positionType:(CornerPositionType)posType {
#if __LP64__
  size = fabs(size);
#else
  size = fabsf(size);
#endif
  CGMutablePathRef path = CGPathCreateMutable();
  CGPoint pStart = point,
          pEnd = point;
  
  switch (posType) {
    case kTopLeft:
      pStart.x += size;
      pEnd.y += size;
      break;
    case kBottomLeft:
      pStart.x += size;
      pEnd.y -= size;
      break;
    case kTopRight:
      pStart.x -= size;
      pEnd.y += size;
      break;
    case kBottomRight:
      pStart.x -= size;
      pEnd.y -= size;
      break;
    default:
      break;
  }
  CGPathMoveToPoint(path, NULL, pStart.x, pStart.y);
  CGPathAddLineToPoint(path, NULL, point.x, point.y);
  CGPathAddLineToPoint(path, NULL, pEnd.x, pEnd.y);
  
  return path;
}

// Animate edge layer
- (void)animateEdgeLayer:(CAShapeLayer *)layer
         toPathFromPoint:(CGPoint)firstPoint
                 toPoint:(CGPoint)secondPoint
         adjustedBy:(CGPoint)adjPoint {
  layer.lineWidth = [self lineWidth];
  
  firstPoint = CGPointMake(firstPoint.x + adjPoint.x, firstPoint.y + adjPoint.y);
  secondPoint = CGPointMake(secondPoint.x - adjPoint.x, secondPoint.y - adjPoint.y);
  CGPathRef newPath = [[self class] newPathFromPoint:firstPoint toPoint:secondPoint];
  [self animateLayer:layer toNewPath:newPath];

  // I used to see occasional crashes stemming from this CGPathRelease. I'm restoring it,
  // since I can no longer reproduce the crashes, and it is a memory leak otherwise. :)
  CGPathRelease(newPath);
}

- (void)animateCornerLayer:(CAShapeLayer *)layer atPoint:(CGPoint)point withPositionType:(CornerPositionType)posType {
  layer.lineWidth = [self lineWidth];
  
  CGPathRef newPath = [[self class] newCornerPathFromPoint:point size:[self cornerSize] positionType:posType];
  [self animateLayer:layer toNewPath:newPath];

  // See above comment on crashes. Same probably applies here. - BPF
  CGPathRelease(newPath);
}

// Animate the layer to a new path.
- (void)animateLayer:(CAShapeLayer *)layer toNewPath:(CGPathRef)newPath {
  if(layer.path) {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.fromValue = (id)layer.path;
    animation.toValue = (__bridge id)newPath;
    animation.duration = 0.25;
    [layer addAnimation:animation forKey:@"animatePath"];
    layer.path = newPath;
  } else {
    layer.path = newPath;
  }
}

- (void)setLayerPaths {
  CGRect guideFrame = self.bounds;
  if(CGRectIsEmpty(guideFrame)) {
    // don't set an empty guide frame -- this helps keep the animations clean, so that
    // we never animate to or from an empty frame, which looks odd.
    return;
  }
  
  CGPoint topLeft = CGPointMake(CGRectGetMinX(guideFrame), CGRectGetMinY(guideFrame));
  CGPoint topRight = CGPointMake(CGRectGetMaxX(guideFrame), CGRectGetMinY(guideFrame));
  CGPoint bottomLeft = CGPointMake(CGRectGetMinX(guideFrame), CGRectGetMaxY(guideFrame));
  CGPoint bottomRight = CGPointMake(CGRectGetMaxX(guideFrame), CGRectGetMaxY(guideFrame));
  
  [self animateEdgeLayer:self.topLayer toPathFromPoint:topLeft toPoint:topRight adjustedBy:[self landscapeHEdgeAdj]];
  [self animateEdgeLayer:self.bottomLayer toPathFromPoint:bottomLeft toPoint:bottomRight adjustedBy:[self landscapeHEdgeAdj]];
  [self animateEdgeLayer:self.leftLayer toPathFromPoint:bottomLeft toPoint:topLeft adjustedBy:[self landscapeVEdgeAdj]];
  [self animateEdgeLayer:self.rightLayer toPathFromPoint:bottomRight toPoint:topRight adjustedBy:[self landscapeVEdgeAdj]];
  
  [self animateCornerLayer:self.topLeftLayer atPoint:topLeft withPositionType:kTopLeft];
  [self animateCornerLayer:self.topRightLayer atPoint:topRight withPositionType:kTopRight];
  [self animateCornerLayer:self.bottomLeftLayer atPoint:bottomLeft withPositionType:kBottomLeft];
  [self animateCornerLayer:self.bottomRightLayer atPoint:bottomRight withPositionType:kBottomRight];
}

- (void)updateStrokes {
  if (self.guidesLockedOn) {
    self.topLayer.hidden = NO;
    self.rightLayer.hidden = NO;
    self.bottomLayer.hidden = NO;
    self.leftLayer.hidden = NO;
  } else {
    if (self.edgeScoreTop > kEdgeOnThreshold) {
      self.topLayer.hidden = NO;
    } else if(self.edgeScoreTop < kEdgeOffThreshold) {
      self.topLayer.hidden = YES;
    }
    if (self.edgeScoreRight > kEdgeOnThreshold) {
      self.rightLayer.hidden = NO;
    } else if(self.edgeScoreRight < kEdgeOffThreshold) {
      self.rightLayer.hidden = YES;
    }
    if (self.edgeScoreBottom > kEdgeOnThreshold) {
      self.bottomLayer.hidden = NO;
    } else if(self.edgeScoreBottom < kEdgeOffThreshold) {
      self.bottomLayer.hidden = YES;
    }
    if (self.edgeScoreLeft > kEdgeOnThreshold) {
      self.leftLayer.hidden = NO;
    } else if(self.edgeScoreLeft < kEdgeOffThreshold) {
      self.leftLayer.hidden = YES;
    }
  }
}

- (void)setFrameInfo:(MyCardIOFrameInfo *)frameInfo {
  _frameInfo = frameInfo;
  
  self.edgeScoreTop = kEdgeDecay * self.edgeScoreTop + (1 - kEdgeDecay) * (frameInfo.foundTopEdge ? 1.0f : -1.0f);
  self.edgeScoreRight = kEdgeDecay * self.edgeScoreRight + (1 - kEdgeDecay) * (frameInfo.foundRightEdge ? 1.0f : -1.0f);
  self.edgeScoreBottom = kEdgeDecay * self.edgeScoreBottom + (1 - kEdgeDecay) * (frameInfo.foundBottomEdge ? 1.0f : -1.0f);
  self.edgeScoreLeft = kEdgeDecay * self.edgeScoreLeft + (1 - kEdgeDecay) * (frameInfo.foundLeftEdge ? 1.0f : -1.0f);

  [self updateStrokes];

  // Update the scores with our decay factor
  float allEdgesFoundScore = (frameInfo.foundAllEdges ? 1.0f : 0.0f);
  self.allEdgesFoundDecayedScore = kAllEdgesFoundScoreDecay * self.allEdgesFoundDecayedScore + (1.0f - kAllEdgesFoundScoreDecay) * allEdgesFoundScore;
  self.numEdgesFoundDecayedScore = kNumEdgesFoundScoreDecay * self.numEdgesFoundDecayedScore + (1.0f - kNumEdgesFoundScoreDecay) * frameInfo.numEdgesFound;

  if (self.allEdgesFoundDecayedScore >= 0.7f) {
    [self showCardFound:YES];
  } else if (self.allEdgesFoundDecayedScore <= 0.1f){
    [self showCardFound:NO];
  }
}

- (void)setGuideColor:(UIColor *)guideColor {
  if(nil == guideColor) {
    [self setGuideColor:[UIColor greenColor]];
    return;
  }

  _guideColor = guideColor;
  
  NSArray *edgeLayers = [NSArray arrayWithObjects:
                         self.topLayer,
                         self.bottomLayer,
                         self.leftLayer,
                         self.rightLayer,
                         self.topLeftLayer,
                         self.topRightLayer,
                         self.bottomLeftLayer,
                         self.bottomRightLayer,
                         nil];

  for(CAShapeLayer *layer in edgeLayers) {
    layer.strokeColor = self.guideColor.CGColor;
  }
}

- (void)showCardFound:(BOOL)found {
  self.guidesLockedOn = found;
  [self updateStrokes];
}

@end
