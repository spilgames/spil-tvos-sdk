//
//  PlayerDataController.h
//  Spil
//
//  Created by Frank Slofstra on 18/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UserProfile;
@class PlayerCurrency;
@class Wallet;
@class Item;
@class Bundle;
@class Inventory;

@interface PlayerDataController : NSObject

+ (PlayerDataController*)sharedInstance;

-(void)requestPlayerData;
-(void)updatePlayerData;
-(void)processPlayerData:(Wallet*)updatedWallet withInventory:(Inventory*)updatedInventory;

-(UserProfile*)getUserProfile;

-(NSString*)getWallet;
-(NSString*)getInventory;

-(void)updateWallet:(int)currencyId withDelta:(int)delta withReason:(NSString*)reason withLocation:(NSString*)location;
-(void)updateInventoryWithItem:(int)itemId withAmount:(int)amount withAction:(NSString*)action withReason:(NSString*)reason withLocation:(NSString*)location;
-(void)updateInventoryWithBundle:(int)bundleId withReason:(NSString*)reason withLocation:(NSString*)location;
-(void)updateUserProfile:(UserProfile*)userProfile;

-(NSString*)loadPlayerDataFromAssets;

-(void)resetPlayerData;
-(void)resetInventory;
-(void)resetWallet;

@end
