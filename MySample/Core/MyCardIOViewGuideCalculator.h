//
//  MyCardIOViewGuideCalculator.h
//  MySample
//
//  Created by Dmytro Trofymenko on 12/6/17.
//

#import <UIKit/UIKit.h>

@interface MyCardIOViewGuideCalculator : NSObject

@property (nonatomic, assign) CGSize videoSize;
@property (nonatomic, assign) CGSize videoViewSize;

- (CGRect)guideFromUIGuide:(CGRect)UIGuide;

@end
