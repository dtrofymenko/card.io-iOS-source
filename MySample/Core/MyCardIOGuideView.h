//
//  MyCardIOGuideView.h
//  MySample
//
//  Created by Dmytro Trofymenko on 12/6/17.
//

#import <Foundation/Foundation.h>
#import "MyCardIOFrameInfo.h"

@protocol MyCardIOGuideView

@property (nonatomic, readonly) CGRect guideFrame;
@property (nonatomic, readonly) UIInterfaceOrientation guideOrientation;
- (void)updateWithFrame:(MyCardIOFrameInfo *)info;

@end
