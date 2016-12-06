//
//  CustomerSupportViewController.h
//  SpilSDKTestProject
//
//  Created by Frank Slofstra on 15/07/16.
//  Copyright © 2016 Frank Slofstra. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SpilTV/Spil.h"

@interface CustomerSupportViewController : UIViewController

@property (retain, nonatomic) UIActivityIndicatorView *spinner;

-(IBAction)onShowHelpCenterPressed:(id)sender;
-(IBAction)onShowContactCenterPressed:(id)sender;
-(IBAction)onShowWebviewPressed:(id)sender;

@end
