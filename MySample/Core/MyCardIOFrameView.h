//
//  MyCardIOFrameView.h
//  MySample
//
//  Created by Dmytro Trofymenko on 12/8/17.
//

#import <UIKit/UIKit.h>
#import "MyCardIOFrameInfo.h"

@interface MyCardIOFrameView : UIView

@property (nonatomic, strong) MyCardIOFrameInfo *frameInfo;
@property (nonatomic, strong) UIColor *guideColor;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) CGFloat cornerSize;

@end
