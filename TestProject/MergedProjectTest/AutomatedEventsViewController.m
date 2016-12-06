//
//  AutomatedEventsViewController.m
//  SpilSDKTestProject
//
//  Created by Martijn van der Gun on 9/14/16.
//  Copyright © 2016 Frank Slofstra. All rights reserved.
//

#import "AutomatedEventsViewController.h"

@interface AutomatedEventsViewController ()

@end

@implementation AutomatedEventsViewController

- (void)viewDidLoad {
    [Spil sharedInstance].delegate = self;
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Splash screen

- (IBAction)requestSplashScreenButtonPressed:(id)sender {
    [Spil requestSplashScreen];
}

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

- (IBAction)requestDailyButtonPressed:(id)sender {
    [Spil requestDailyBonus];
}

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

-(void)playerDataUpdated:(NSString*)reason updatedData:(NSString*)updatedData {
    NSLog(@"playerDataUpdated, reason: %@, data: %@", reason, updatedData);
}

-(void)playerDataError:(NSString*)message {
    NSLog(@"playerDataError: %@", message);
}

@end
