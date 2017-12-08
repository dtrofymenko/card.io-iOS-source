//
//  MyCardIOStream.h
//  MySample
//
//  Created by Dmytro Trofymenko on 12/6/17.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MyCardIOStreamConfiguration.h"
#import "MyCardIOFrameInfo.h"

@class MyCardIOStream;
@protocol MyCardIOStreamDelegate

- (void)cardIOStream:(MyCardIOStream *)stream didProcessFrame:(MyCardIOFrameInfo *)aFrameInfo;

@end

@interface MyCardIOStream: NSObject

- (id)initWithConfiguration:(MyCardIOStreamConfiguration *)configuration;

- (void)start;
- (void)stop;
@property (nonatomic, assign, readonly, getter = isStarted) BOOL started;

@property (nonatomic, assign) CGRect guide;
@property (nonatomic, assign) UIInterfaceOrientation guideOrientation;

@property (nonatomic, assign, readonly) CGSize videoSize;

@property (nonatomic, strong, readonly) AVCaptureSession *session;

@property (nonatomic, weak) id<MyCardIOStreamDelegate> delegate;

@end
