//
//  WalletTestViewController.h
//  SpilSDKTestProject
//
//  Created by Frank Slofstra on 20/05/16.
//  Copyright © 2016 Frank Slofstra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpilTV/Spil.h"

@interface WalletTestViewController : UIViewController<SpilDelegate>

@property (weak, nonatomic) IBOutlet UITextView *currencyInfoTextView;
@property (weak, nonatomic) IBOutlet UITextField *currencyTextField;
@property (weak, nonatomic) IBOutlet UITextField *itemTextField;
@property (weak, nonatomic) IBOutlet UITextField *bundleTextField;

- (IBAction)onPlusButtonPressed:(id)sender;
- (IBAction)onMinusButtonPressed:(id)sender;

- (IBAction)onAddItemButtonPressed:(id)sender;
- (IBAction)onRemoveItemButtonPressed:(id)sender;

- (IBAction)onAddBundleButtonPressed:(id)sender;

- (IBAction)onRefreshButtonPressed:(id)sender;

@end
