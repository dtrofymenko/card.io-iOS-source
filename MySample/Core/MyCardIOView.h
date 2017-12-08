//
//  MyCardIOView.h
//  MySample
//
//  Created by Dmytro Trofymenko on 12/6/17.
//

#import <UIKit/UIKit.h>
#import "MyCardIOConfiguration.h"

@class MyCardIOView;
@protocol MyCardIOViewDelegate

- (void)cardIOView:(MyCardIOView *)view didComplete:(MyCardIInfo *)info;

@end

@interface MyCardIOView : UIView

- (id)initWithConfiguration:(MyCardIOConfiguration *)configuration;
@property (nonatomic, strong, readonly) UIView<MyCardIOGuideView> *guideView;

- (void)start;
- (void)stop;
@property (nonatomic, assign, readonly, getter = isStarted) BOOL started;
@property (nonatomic, weak) id<MyCardIOViewDelegate> delegate;

@end
