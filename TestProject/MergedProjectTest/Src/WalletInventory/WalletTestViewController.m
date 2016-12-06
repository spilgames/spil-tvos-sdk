//
//  WalletTestViewController.m
//  SpilSDKTestProject
//
//  Created by Frank Slofstra on 20/05/16.
//  Copyright © 2016 Frank Slofstra. All rights reserved.
//`

#import "WalletTestViewController.h"
#import "AppDelegate.h"
#import "SpilTV/JsonUtil.h"
//#import "SpilTV/PlayerDataUpdateReasons.h"

@implementation WalletTestViewController

@synthesize currencyTextField;
@synthesize currencyInfoTextView;
@synthesize itemTextField;
@synthesize bundleTextField;

- (void)viewDidLoad {
    [self.currencyTextField setDelegate:(id<UITextFieldDelegate>)self];
    [self.currencyTextField addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.itemTextField setDelegate:(id<UITextFieldDelegate>)self];
    [self.itemTextField addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.bundleTextField setDelegate:(id<UITextFieldDelegate>)self];
    [self.bundleTextField addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.currencyInfoTextView.textContainer.lineFragmentPadding = 0;
    self.currencyInfoTextView.textContainerInset = UIEdgeInsetsZero;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [Spil sharedInstance].delegate = self;
    
    [self updateCurrencyInfo];
}

- (IBAction)onPlusButtonPressed:(id)sender {
    int currencyId = [self.currencyTextField.text intValue];
    [Spil addCurrencyToWallet:currencyId withAmount:100 withReason:@"add"];
    [currencyTextField resignFirstResponder];
}

- (IBAction)onMinusButtonPressed:(id)sender {
    int currencyId = [self.currencyTextField.text intValue];
    [Spil subtractCurrencyFromWallet:currencyId withAmount:100 withReason:@"subtract"];
    [currencyTextField resignFirstResponder];
}

- (IBAction)onRefreshButtonPressed:(id)sender {
    [self updateCurrencyInfo];
}

- (void)updateCurrencyInfo {
    // Convert from and to json using the util for beter readability
    NSString *wallet = [JsonUtil convertStringToObject:[Spil getWallet]];
    NSString *inventory = [JsonUtil convertStringToObject:[Spil getInventory]];
    NSString *gamedata = [JsonUtil convertStringToObject:[Spil getSpilGameData]];
    dispatch_async(dispatch_get_main_queue(), ^{
        currencyInfoTextView.text = [NSString stringWithFormat:@"----- Wallet -----\n %@ \n\n ----- Inventory -----\n %@ \n\n----- GameData -----\n %@", wallet, inventory, gamedata];
        [currencyInfoTextView setContentOffset:CGPointZero animated:NO];
    });
}

- (IBAction)textFieldFinished:(id)sender {
    [sender resignFirstResponder];
}

-(void)playerDataAvailable {
    [self updateCurrencyInfo];
    NSLog(@"[WalletTestViewController] PlayerDataAvailable!");
}

-(void)playerDataError:(NSString*)message {
    [self updateCurrencyInfo];
    NSLog(@"[WalletTestViewController] playerDataError! %@", message);
}

- (IBAction)onAddItemButtonPressed:(id)sender {
    int itemId = [self.itemTextField.text intValue];
    [Spil addItemToInventory:itemId withAmount:1 withReason:@"add"];
}

- (IBAction)onRemoveItemButtonPressed:(id)sender {
    int itemId = [self.itemTextField.text intValue];
    [Spil subtractItemFromInventory:itemId withAmount:1 withReason:@"add"];
}

- (IBAction)onAddBundleButtonPressed:(id)sender {
    int itemId = [self.bundleTextField.text intValue];
    [Spil consumeBundle:itemId withReason:@"bought"];
}

-(void)playerDataUpdated:(NSString*)reason updatedData:(NSString*)updatedData  {
    [self updateCurrencyInfo];
    NSLog(@"[WalletTestViewController] playerDataUpdated!");
}

@end
