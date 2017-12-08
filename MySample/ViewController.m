//
//  ViewController.m
//  MySample
//
//  Created by Dmytro Trofymenko on 12/6/17.
//

#import "ViewController.h"
#import "ScanSampleViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *frontCameraSwitch;

@end

@implementation ViewController

- (void)viewDidLoad {
   [super viewDidLoad];
}

- (IBAction)scan:(id)sender {
  ScanSampleViewController *viewController = [[ScanSampleViewController alloc] init];
  viewController.frontCamera = self.frontCameraSwitch.on;
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
  [self presentViewController:navigationController animated:YES completion:nil];
}

@end
