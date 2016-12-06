//
//  IAPViewController.h
//  SpilSDKTestProject
//
//  Created by Frank Slofstra on 27/10/16.
//  Copyright © 2016 Frank Slofstra. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface IAPViewController : UIViewController <SKProductsRequestDelegate, SKPaymentTransactionObserver> //UITableViewDelegate, UITableViewDataSource,

@property (weak, nonatomic) IBOutlet UITableView *tableview;

@property (weak, nonatomic) IBOutlet UITextField *iapTextfield;
- (IBAction)validateIAPPressed:(id)sender;

@end
