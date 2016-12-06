//
//  IAPTableViewCell.h
//  SpilSDKTestProject
//
//  Created by Frank Slofstra on 27/10/16.
//  Copyright © 2016 Frank Slofstra. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IAPTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *buyButton;

- (void)setup:(NSString*)description price:(NSString*)price;

@end
