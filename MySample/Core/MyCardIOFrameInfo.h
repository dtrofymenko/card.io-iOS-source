//
//  MyCardIOFrameInfo.h
//  MySample
//
//  Created by Dmytro Trofymenko on 12/7/17.
//

#import "MyCardIInfo.h"

@interface MyCardIOFrameInfo: NSObject

@property (nonatomic, readonly) BOOL foundTopEdge;
@property (nonatomic, readonly) BOOL foundBottomEdge;
@property (nonatomic, readonly) BOOL foundLeftEdge;
@property (nonatomic, readonly) BOOL foundRightEdge;

@property (nonatomic, readonly) BOOL foundAllEdges;
@property (nonatomic, readonly) NSInteger numEdgesFound;

@property (nonatomic, readonly) BOOL completed;
@property (nonatomic, strong, readonly) MyCardIInfo *cardInfo;

@end
