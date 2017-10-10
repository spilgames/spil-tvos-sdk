//
//  SpilUserHandler.m
//  Spil
//
//  Created by Frank Slofstra on 04/07/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "SpilUserHandler.h"
#import "SpilEventTracker.h"
#import "Spil.h"
#import "SpilError.h"

@interface SpilUserHandler ()

@property (nonatomic, retain) NSString *externalUserProvider;
@property (nonatomic, retain) NSString *externalUserId;
@property (nonatomic, retain) NSString *activeUserId;
@property (nonatomic, assign) BOOL duplicateUserId;

@end

@implementation SpilUserHandler

@synthesize externalUserProvider;
@synthesize externalUserId;
@synthesize activeUserId;
@synthesize duplicateUserId;

static SpilUserHandler* sharedInstance;

+ (SpilUserHandler*)sharedInstance {
    static SpilUserHandler *instance = nil;
    if (instance == nil)
    {
        // structure used to test whether the block has completed or not
        static dispatch_once_t p;
        dispatch_once(&p, ^{
            instance = [[SpilUserHandler alloc] init];
        });
    }
    
    return instance;
}

-(id)init {
    self = [super init];
    self.activeUserId = @"";
    self.duplicateUserId = false;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.externalUserProvider = [defaults objectForKey:@"externalUserProvider"];
    self.externalUserId = [defaults objectForKey:@"externalUserId"];
    
    return self;
}

#pragma mark Spil User ID

-(void)syncSpilUserId {
    NSString *userToken = nil;
    
    // Try to find an existing user token in iCloud
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSURL *dataUrl = [[fileManager URLForUbiquityContainerIdentifier:@"iCloud.com.spilgames.shared"] URLByAppendingPathComponent:@"Documents/userinfo.data"];
    NSData *data = [NSData dataWithContentsOfURL:dataUrl];
    if (data != nil) {
        NSDictionary *kvs = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSString *token = kvs[@"userId"];
        if (token != nil) {
            userToken = token;
            NSLog(@"[SpilUserHandler] user token found in iCloud: %@", userToken);
        }
    }
    
    // Try to find an existing user token in userDefaults if it wasn't found in iCloud
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.spilgames"];
    NSString *token = [userDefaults objectForKey:@"com.spilgames.userid"];
    if (token != nil) {
        if (userToken == nil) {
            userToken = token;
            NSLog(@"[SpilUserHandler] user token found in userDefaults: %@", userToken);
        } else if (userToken != nil && ![token isEqualToString:userToken]) {
            duplicateUserId = true;
            userToken = token;
            NSLog(@"[SpilUserHandler] duplicate user token found in iCloud and userDefaults: %@, %@ using userDefault token: %@", userToken, token, token);
        }
    }
    
    // Generate a new user token if it was not found in iCloud or in userDefaults
    if (userToken == nil) {
        userToken = [[NSUUID UUID] UUIDString];
        NSLog(@"[SpilUserHandler] user token not found, generated a new one: %@", userToken);
    }
    
    // Sync the user token with iCloud and userDefaults
    if (userToken != nil) {
        // Writing to userDefaults
        [userDefaults setObject:userToken forKey:@"com.spilgames.userid"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        
        // Writing to iCloud
        NSDictionary *kvs = @{@"userId" : userToken};
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:kvs];
        [data writeToURL:dataUrl atomically:true];
        
        // Keep local reference
        activeUserId = userToken;
    } else {
        NSLog(@"[SpilUserHandler] failed to find or create user token!");
    }
}

-(void)handleDuplicateUserId {
    if (duplicateUserId) {
        [[SpilEventTracker sharedInstance] trackEvent:@"duplicate_usertoken"];
    }
}

-(NSString*)getUserId{
    return activeUserId;
}

#pragma mark External User ID

-(void)setExternalUserId:(NSString*)userId forProviderId:(NSString*)providerId {
    externalUserProvider = providerId;
    externalUserId = userId;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:externalUserProvider forKey:@"externalUserProvider"];
    [defaults setObject:externalUserId forKey:@"externalUserId"];
    [defaults synchronize];
}

-(NSString*)getExternalUserId{
    return externalUserId;
}

-(NSString*)getExternalUserProvider {
    return externalUserProvider;
}

-(NSDictionary*)getExternalUserRequestData {
    if (externalUserProvider == nil || externalUserId == nil) {
        return nil;
    } else {
        return @{ @"provider" : externalUserProvider, @"userId" : externalUserId };
    }
}

#pragma mark User data

-(void)setPrivateGameState:(NSString*)privateData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:privateData forKey:@"privateGameStateData"];
    [defaults synchronize];
    
    NSDictionary *data = @{ @"access" : @"private", @"data" : privateData};
    [Spil trackEvent:@"updateGameState" withParameters:data];
}

-(NSString*)getPrivateGameState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *gameObjects = [defaults objectForKey:@"privateGameStateData"];
    if (gameObjects == nil) {
        NSDictionary *userInfo = @{@"event" : @"gameStateError", @"message" : [[SpilError PublicGameStateOperationFailed:@"Private GameState not found!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
    }
    return gameObjects;
}

-(void)setPublicGameState:(NSString*)publicData {
    if ([self getExternalUserRequestData] == nil) {
        if (![publicData isEqualToString:@""]) {
            NSDictionary *userInfo = @{@"event" : @"gameStateError", @"message" : [[SpilError PublicGameStateOperationFailed:@"User id not set!"] toJson]};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        }
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:publicData forKey:@"publicGameStateData"];
    [defaults synchronize];
    
    NSDictionary *data = @{ @"access" : @"public", @"data" : publicData};
    [Spil trackEvent:@"updateGameState" withParameters:data];
}

-(NSString*)getPublicGameState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *gameState = [defaults objectForKey:@"publicGameStateData"];
    if (gameState == nil) {
        NSDictionary *userInfo = @{@"event" : @"gameStateError", @"message" : [[SpilError PublicGameStateOperationFailed:@"Public GameState not found!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
    }
    return gameState;
}

-(void)getOtherUsersGameState:(NSString*)provider userIds:(NSArray*)userIds {
    NSDictionary *data = @{ @"provider" : provider, @"users" : userIds };
    [Spil trackEvent:@"requestOtherUsersGameState" withParameters:data onResponse:^(id response) {
        if ([response isKindOfClass:[NSDictionary class]] && response[@"error"] != nil) {
            NSDictionary *userInfo = @{@"event" : @"gameStateError", @"message" : [[SpilError GameStateServerError:@"Other users gameState load failed!"] toJson]};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        }
    }];
}

-(void)getMyGameState {
    NSMutableArray *access = [NSMutableArray array];
    [access addObject:@"private"];
    if ([self getExternalUserRequestData] != nil) {
        [access addObject:@"public"];
    }
    NSDictionary *data = @{ @"access" : access };
    [Spil trackEvent:@"requestMyGameState" withParameters:data];
}

#pragma mark Updates

-(void)gameStateUpdateReceived:(NSString*)privateData public:(NSString*)publicData {
    [self setPrivateGameState:privateData];
    [self setPublicGameState:publicData];
    
    if (publicData != nil && [publicData length] > 0) {
        NSDictionary *userInfoPublic = @{@"event" : @"gameStateUpdated", @"data" : publicData, @"access" : @"public"};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfoPublic];
    }
    if (privateData != nil && [privateData length] > 0) {
        NSDictionary *userInfoPrivate = @{@"event" : @"gameStateUpdated", @"data" : privateData, @"access" : @"private"};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfoPrivate];
    }
}

-(void)friendsGameStateLoaded:(NSDictionary*)gameStates provider:(NSString*)provider {
    NSDictionary *userInfoPrivate = @{@"event" : @"otherUsersGameStateLoaded", @"data" : gameStates, @"provider" : provider};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfoPrivate];
}

@end
