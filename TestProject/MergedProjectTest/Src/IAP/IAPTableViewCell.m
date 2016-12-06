//
//  IAPTableViewCell.m
//  SpilSDKTestProject
//
//  Created by Frank Slofstra on 27/10/16.
//  Copyright © 2016 Frank Slofstra. All rights reserved.
//

#import "IAPTableViewCell.h"

@implementation IAPTableViewCell

@synthesize descriptionLabel;
@synthesize buyButton;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setup:(NSString*)description price:(NSString*)price {
    descriptionLabel.text = description;
    [buyButton setTitle:price forState:UIControlStateNormal];
    [buyButton setUserInteractionEnabled:false];
}

@end
