//
//  MyCardIOConfiguration.m
//  MySample
//
//  Created by Dmytro Trofymenko on 12/6/17.
//

#import "MyCardIOConfiguration.h"

@implementation MyCardIOConfiguration

- (id)init {
  self = [super init];
  if (nil != self) {
    self.streamConfiguration = [[MyCardIOStreamConfiguration alloc] init];
  }
  return self;
}

@end
