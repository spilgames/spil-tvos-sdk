//
//  AutomatedEventsViewController.h
//  SpilSDKTestProject
//
//  Created by Martijn van der Gun on 9/14/16.
//  Copyright © 2016 Frank Slofstra. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SpilTV/Spil.h"

@interface AutomatedEventsViewController : UIViewController<SpilDelegate>

- (IBAction)requestDailyButtonPressed:(id)sender;
- (IBAction)requestSplashScreenButtonPressed:(id)sender;

@end
