//
//  MyCardIOConfiguration.h
//  MySample
//
//  Created by Dmytro Trofymenko on 12/6/17.
//

#import <UIKit/UIKit.h>
#import "MyCardIOGuideView.h"
#import "MyCardIOStreamConfiguration.h"

@interface MyCardIOConfiguration : NSObject

@property (nonatomic, strong) UIView<MyCardIOGuideView> *guideView;
@property (nonatomic, strong) MyCardIOStreamConfiguration *streamConfiguration;

@end
