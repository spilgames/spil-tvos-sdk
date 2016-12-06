//
//  MainViewController.m
//  SpilSDKTestProject
//
//  Created by Frank Slofstra on 24/11/16.
//  Copyright © 2016 Frank Slofstra. All rights reserved.
//

#import "MainViewController.h"
#import "SpilTV/Spil.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [Spil sharedInstance].delegate = self;
}

#pragma mark Delegates

-(void)adAvailable:(NSString*)type {
    NSLog(@"adAvailable delegate %@", type);
}

-(void)adNotAvailable:(NSString*)type {
    NSLog(@"adNotAvailable delegate %@", type);
}

-(void)adStart {
    NSLog(@"adDidShow delegate");
}

-(void)adFinished:(NSString*)adType reason:(NSString*)reason reward:(NSString*)reward network:(NSString*)network {
    NSLog(@"adFinished delegate, adType: %@, reason: %@, network: %@, reward: %@", adType, reason, network, reward);
}

-(void)grantReward:(NSDictionary*)data {
    NSLog(@"notificationReward delegate %@", data);
}

-(void)packagesLoaded {
    NSLog(@"packagesLoaded delegate");
}

-(void)gameDataAvailable {
    NSLog(@"gameDataAvailable delegate");
}

-(void)configUpdated {
    NSLog(@"configUpdated delegate");
}

-(void)gameDataError:(NSString*)message {
    NSLog(@"gameDataError delegate %@", message);
}

-(void)playerDataAvailable {
    NSLog(@"playerDataAvailable delegate");
}

-(void)playerDataError:(NSString*)message {
    NSLog(@"playerDataError delegate %@", message);
}

-(void)playerDataUpdated:(NSString*)reason updatedData:(NSString*)updatedData {
    NSLog(@"playerDataUpdated delegate");
}

// Splash screen

-(void)splashScreenOpen {
    NSLog(@"splashScreenOpen!");
}

-(void)splashScreenClosed {
    NSLog(@"splashScreenClosed!");
}

-(void)splashScreenOpenShop {
    NSLog(@"splashScreenOpenShop!");
}

-(void)splashScreenError:(NSString*)message {
    NSLog(@"message! %@", message);
}

// Daily bonus

-(void)dailyBonusOpen {
    NSLog(@"dailyBonusOpen!");
}

-(void)dailyBonusClosed {
    NSLog(@"dailyBonusClosed!");
}

-(void)dailyBonusReward:(NSDictionary*)data {
    NSLog(@"dailyBonusReward! %@", data);
}

-(void)dailyBonusError:(NSString*)message {
    NSLog(@"dailyBonusError! %@", message);
}

-(IBAction)onButton1Pressed:(id)sender {
    NSDictionary *data = @{@"levelName":@"1"};
    [Spil trackEvent:@"levelComplete" withParameters:data];
}

-(IBAction)onButton2Pressed:(id)sender {

}

-(IBAction)onButton3Pressed:(id)sender {
    [Spil trackEvent:@"requestRewardVideo"];
//    [Spil devRequestAd:@"rewardVideo" withAdType:@"rewardvideo" withParentalGate:NO];
}

-(IBAction)onButton4Pressed:(id)sender {
    [Spil playRewardVideo];
}

@end
