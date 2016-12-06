//
//  SpilUserHandler.h
//  Spil
//
//  Created by Frank Slofstra on 04/07/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpilUserHandler : NSObject

+(SpilUserHandler*)sharedInstance;

// Spil user id

-(void)syncSpilUserId;
-(void)handleDuplicateUserId;
-(NSString*)getUserId;

// External user id

-(void)setExternalUserId:(NSString*)userId forProviderId:(NSString*)providerId;
-(NSString*)getExternalUserId;
-(NSString*)getExternalUserProvider;
-(NSDictionary*)getExternalUserRequestData;

// User data

-(void)setPrivateGameState:(NSString*)privateData;
-(NSString*)getPrivateGameState;
-(void)setPublicGameState:(NSString*)publicData;
-(NSString*)getPublicGameState;
-(void)getOtherUsersGameState:(NSString*)provider userIds:(NSArray*)userIds;
-(void)getMyGameState;

// Updates

-(void)gameStateUpdateReceived:(NSString*)privateData public:(NSString*)publicData;
-(void)friendsGameStateLoaded:(NSDictionary*)gameStates provider:(NSString*)provider;

@end