//
//  ScanSampleViewController.m
//  MySample
//
//  Created by Dmytro Trofymenko on 12/6/17.
//

#import "ScanSampleViewController.h"
#import "MyCardIOView.h"
#import "MyCardIOStandartGuideView.h"
#import "ScanResultSampleViewController.h"

@interface ScanSampleViewController () <MyCardIOViewDelegate>

@property (nonatomic, strong) MyCardIOView *cardIOView;

@end

@implementation ScanSampleViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                        target:self
                                                                                        action:@selector(close:)];
  MyCardIOConfiguration *configuration = [[MyCardIOConfiguration alloc] init];
  configuration.guideView = [[MyCardIOStandartGuideView alloc] init];
  if (self.frontCamera) {
    configuration.streamConfiguration.device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
  }
  self.cardIOView = [[MyCardIOView alloc] initWithConfiguration:configuration];
  self.cardIOView.frame = self.view.bounds;
  self.cardIOView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.cardIOView.delegate = self;
  
  [self.view addSubview:self.cardIOView];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.cardIOView start];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [self.cardIOView stop];
}

- (void)close:(id)sender {
  [self dismissViewControllerAnimated:self completion:nil];
}

#pragma mark - MyCardIOViewDelegate

- (void)cardIOView:(MyCardIOView *)view didComplete:(MyCardIInfo *)info {
  ScanResultSampleViewController *viewController = [[ScanResultSampleViewController alloc] init];
  viewController.cardInfo = info;
  [self.navigationController pushViewController:viewController animated:YES];
}

@end
