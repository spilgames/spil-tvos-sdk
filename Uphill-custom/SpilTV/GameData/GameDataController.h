//
//  GameDataController.h
//  Spil
//
//  Created by Frank Slofstra on 18/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GameData;
@class Item;
@class Bundle;
@class Currency;
@class ShopPromotion;

@interface GameDataController : NSObject

+(GameDataController*)sharedInstance;

-(void)requestGameData;
-(void)processGameData:(NSDictionary*)data;
-(GameData*)getGameData;

-(Item*)getItem:(int)itemId;
-(Currency*)getCurrency:(int)currency;
-(Bundle*)getBundle:(int)bundleId;

-(NSString*)getShop;
-(NSString*)getShopPromotions;
-(ShopPromotion*)getPromotion:(int)bundleId;

-(void)updateGameData:(GameData*)gameData;

-(NSString*)loadGameDataFromAssets;
 
@end
