//
//  UserDataVC.h
//  SpilSDKTestProject
//
//  Created by Frank Slofstra on 17/08/16.
//  Copyright © 2016 Frank Slofstra. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SpilTV/Spil.h"

@interface UserDataVC : UIViewController<UITextViewDelegate, SpilDelegate>

@property (weak, nonatomic) IBOutlet UITextField *userIdTextField;
@property (weak, nonatomic) IBOutlet UITextField *providerIdTextField;

@property (weak, nonatomic) IBOutlet UITextField *otherUsersProviderTextField;
@property (weak, nonatomic) IBOutlet UITextField *otherUsersUserIdsTextField;

@property (weak, nonatomic) IBOutlet UITextView *privateDataTextView;
@property (weak, nonatomic) IBOutlet UITextView *publicDataTextView;
@property (weak, nonatomic) IBOutlet UITextView *friendsDataTextView;

-(IBAction)setUserId:(id)sender;
-(IBAction)savePrivateData:(id)sender;
-(IBAction)savePublicData:(id)sender;
-(IBAction)getFriendsData:(id)sender;

@end
