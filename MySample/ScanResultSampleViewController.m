//
//  ScanResultSampleViewController.m
//  MySample
//
//  Created by Dmytro Trofymenko on 12/8/17.
//

#import "ScanResultSampleViewController.h"

@interface ScanResultSampleViewController ()
@property (weak, nonatomic) IBOutlet UILabel *numberLabel;
@property (weak, nonatomic) IBOutlet UIImageView *cardImageView;
@property (weak, nonatomic) IBOutlet UIImageView *fullImageView;

@end

@implementation ScanResultSampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.numberLabel.text = self.cardInfo.cardNumber;
    self.cardImageView.image = self.cardInfo.cardImage;
    self.fullImageView.image = self.cardInfo.fullImage;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
