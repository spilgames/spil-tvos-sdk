//
//  UserDataVC.m
//  SpilSDKTestProject
//
//  Created by Frank Slofstra on 17/08/16.
//  Copyright © 2016 Frank Slofstra. All rights reserved.
//

#import "UserDataVC.h"
#import "SpilTV/Spil.h"

@implementation UserDataVC

@synthesize userIdTextField;
@synthesize providerIdTextField;
@synthesize otherUsersProviderTextField;
@synthesize otherUsersUserIdsTextField;
@synthesize privateDataTextView;
@synthesize publicDataTextView;
@synthesize friendsDataTextView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.userIdTextField setDelegate:(id<UITextFieldDelegate>)self];
    [self.userIdTextField addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.providerIdTextField setDelegate:(id<UITextFieldDelegate>)self];
    [self.providerIdTextField addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.otherUsersProviderTextField setDelegate:(id<UITextFieldDelegate>)self];
    [self.otherUsersProviderTextField addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.otherUsersUserIdsTextField setDelegate:(id<UITextFieldDelegate>)self];
    [self.otherUsersUserIdsTextField addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    privateDataTextView.text = [Spil getPrivateGameState];
    publicDataTextView.text = [Spil getPublicGameState];
}

- (void)viewWillAppear:(BOOL)animated {
    [Spil sharedInstance].delegate = self;
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [Spil sharedInstance].delegate = nil;
    [super viewWillDisappear:animated];
}

-(IBAction)setUserId:(id)sender {
    [Spil setUserId:userIdTextField.text forProviderId:providerIdTextField.text];
}

-(IBAction)savePrivateData:(id)sender {
    [Spil setPrivateGameState:privateDataTextView.text];
}

-(IBAction)savePublicData:(id)sender {
    [Spil setPublicGameState:publicDataTextView.text];
}

-(IBAction)getFriendsData:(id)sender {
    NSArray *rawUserIds = [otherUsersUserIdsTextField.text componentsSeparatedByString:@","];
    NSMutableArray *userIds = [NSMutableArray array];
    for (NSString *rawUserId in rawUserIds) {
        NSString *userId = [rawUserId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [userIds addObject:userId];
    }
    [Spil getOtherUsersGameState:otherUsersProviderTextField.text userIds:userIds];
}

#pragma mark Spil Delegates

-(void)gameStateUpdated:(NSString*)access {
    NSLog(@"gameStateUpdated: %@", access);
    
    privateDataTextView.text = [Spil getPrivateGameState];
    publicDataTextView.text = [Spil getPublicGameState];
}

-(void)otherUsersGameStateLoaded:(NSDictionary*)data forProvider:(NSString*)provider {
    NSLog(@"otherUsersGameStateLoaded: %@ provider: %@", data, provider);
    
    friendsDataTextView.text = [NSString stringWithFormat:@"%@, provider: %@", [JsonUtil convertObjectToJson:data], provider];
}

-(void)gameStateError:(NSString*)message {
    NSLog(@"gameStateError: %@", message);
}

#pragma mark TextField Delegates

- (IBAction)textFieldFinished:(id)sender {
    [sender resignFirstResponder];
}

@end
