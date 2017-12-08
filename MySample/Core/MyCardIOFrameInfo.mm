//
//  MyCardIOFrameInfo.m
//  MySample
//
//  Created by Dmytro Trofymenko on 12/7/17.
//

#import "MyCardIOFrameInfo.h"
#import "CardIOVideoFrame.h"
#import "CardIOCardScanner.h"
#import "CardIOReadCardInfo.h"

@interface MyCardIOFrameInfo()

@property (nonatomic, strong) CardIOVideoFrame *frame;
@property (nonatomic, assign) BOOL completed;
@property (nonatomic, strong) MyCardIInfo *cardInfo;

@end

@implementation MyCardIOFrameInfo

- (id)initWithFrame:(CardIOVideoFrame *)frame {
  self = [super init];
  if (nil != self) {
    self.frame = frame;
    [self setup];
  }
  return self;
}

- (BOOL)foundTopEdge {
  return self.frame.foundLeftEdge;
}

- (BOOL)foundBottomEdge {
  return self.frame.foundRightEdge;
}

- (BOOL)foundLeftEdge {
  return self.frame.foundBottomEdge;
}

- (BOOL)foundRightEdge {
  return self.frame.foundTopEdge;
}

- (BOOL)foundAllEdges {
  return self.foundLeftEdge && self.foundRightEdge && self.foundTopEdge && self.foundBottomEdge;
}

- (NSInteger)numEdgesFound {
  return (self.foundLeftEdge ? 1 : 0)
  + (self.foundRightEdge ? 1 : 0)
  + (self.foundTopEdge ? 1 : 0)
  + (self.foundBottomEdge ? 1 : 0);
}

#pragma mark - Private

- (void)setup {
  if (self.frame.detectionMode == CardIODetectionModeCardImageAndNumber ||
      self.frame.detectionMode == CardIODetectionModeAutomatic) {
    self.completed = self.frame.scanner.complete;
  } else if (self.frame.detectionMode == CardIODetectionModeCardImageOnly) {
    self.completed = self.frame.focusOk && self.frame.foundAllEdges;
  }
  
  if (self.completed) {
    MyCardIInfo *creditCardInfo = [[MyCardIInfo alloc] init];
    creditCardInfo.cardImage = [self.frame imageWithGrayscale:false];
    creditCardInfo.fullImage = [self.frame fullImage];
    creditCardInfo.cardNumber = self.frame.cardInfo.numbers;
    self.cardInfo = creditCardInfo;
  }
}

//- (void)videoStream:(CardIOVideoStream *)stream didProcessFrame:(CardIOVideoFrame *)processedFrame {
//  [self didDetectCard:processedFrame];
//
//  if(processedFrame.scanner.complete) {
//    [self didScanCard:processedFrame];
//  }
//}
//
//- (void)didDetectCard:(CardIOVideoFrame *)processedFrame {
//  if(processedFrame.foundAllEdges && processedFrame.focusOk) {
//    if(self.detectionMode == CardIODetectionModeCardImageOnly) {
//      [self stopSession];
//      [self vibrate];
//
//      CardIOCreditCardInfo *cardInfo = [[CardIOCreditCardInfo alloc] init];
//      self.cardImage = [processedFrame imageWithGrayscale:NO];
//      cardInfo.cardImage = self.cardImage;
//
//      [self.config.scanReport reportEventWithLabel:@"scan_detection" withScanner:processedFrame.scanner];
//
//      [self successfulScan:cardInfo];
//    }
//  }
//}
//
//- (void)didScanCard:(CardIOVideoFrame *)processedFrame {
//  [self stopSession];
//  [self vibrate];
//
//  self.readCardInfo = processedFrame.scanner.cardInfo;
//  CardIOCreditCardInfo *cardInfo = [[CardIOCreditCardInfo alloc] init];
//  cardInfo.cardNumber = self.readCardInfo.numbers;
//  cardInfo.expiryMonth = self.readCardInfo.expiryMonth;
//  cardInfo.expiryYear = self.readCardInfo.expiryYear;
//  cardInfo.scanned = YES;
//
//  self.cardImage = [processedFrame imageWithGrayscale:NO];
//  cardInfo.cardImage = self.cardImage;
//
//  [self.config.scanReport reportEventWithLabel:@"scan_success" withScanner:processedFrame.scanner];
//
//  [self successfulScan:cardInfo];
//}


@end
