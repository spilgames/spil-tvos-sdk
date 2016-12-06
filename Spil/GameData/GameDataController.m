//
//  GameDataController.m
//  Spil
//
//  Created by Frank Slofstra on 18/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "Spil.h"
#import "GameDataController.h"
#import "GameData.h"
#import "Item.h"
#import "Bundle.h"
#import "SpilEventTracker.h"
#import "Currency.h"
#import "SpilError.h"
#import "NSArray+JSONModelExtensions.h"
#import "JsonModel.h"
#import "Util.h"

@implementation GameDataController

static GameDataController* sharedInstance;
+ (GameDataController*)sharedInstance {
    static GameDataController *gameDataController = nil;
    if (gameDataController == nil) {
        static dispatch_once_t p;
        dispatch_once(&p, ^{
            gameDataController = [[GameDataController alloc] init];
        });
    }
    return gameDataController;
}

-(void)requestGameData {
    [[SpilEventTracker sharedInstance] trackEvent:@"requestGameData"];
}

-(void)processGameData:(NSDictionary*)data {
    NSError *error = nil;
    NSMutableArray *currencies = [Currency arrayOfModelsFromDictionaries:data[@"currencies"] error:&error];
    NSMutableArray *items = [Item arrayOfModelsFromDictionaries:data[@"items"] error:&error];
    NSMutableArray *bundles = nil;//[Bundle arrayOfModelsFromDictionaries:data[@"bundles"] error:&error];
    NSMutableArray *shopTabs = [ShopTab arrayOfModelsFromDictionaries:data[@"shop"] error:&error];
    NSMutableArray *shopPromotions = [ShopPromotion arrayOfModelsFromDictionaries:data[@"promotions"] error:&error];
    [[GameDataController sharedInstance] processGameData:currencies withItems:items withBundles:bundles withShopTabs:shopTabs withShopPromotions:shopPromotions];
}

-(void)processGameData:(NSArray*)currencies withItems:(NSArray*)items withBundles:(NSArray*)bundles withShopTabs:(NSArray*)shopTabs withShopPromotions:(NSArray*)shopPromotions {
    GameData *gameData = [self getGameData];
    
    if (gameData != nil) {
        gameData.currencies = [currencies mutableCopy];
        gameData.items = [items mutableCopy];
        gameData.bundles = [bundles mutableCopy];
        gameData.shop = [shopTabs mutableCopy];
        gameData.promotions = [shopPromotions mutableCopy];
        
        [self updateGameData:gameData];
        
        // Send a notification when the data is loaded
        NSDictionary *userInfo = @{@"event" : @"gameDataAvailable"};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
    }
}

-(GameData*)getGameData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *gameObjects = [defaults objectForKey:@"spilGameData"];

    if(gameObjects != nil){
        NSError *error = nil;
        return [[GameData alloc] initWithString:gameObjects error:&error];
    } else {
        gameObjects = [self loadGameDataFromAssets];
        
        if(gameObjects != nil){
            [defaults setObject:gameObjects forKey:@"spilGameData"];
            [defaults synchronize];
            
            NSError *error = nil;
            return [[GameData alloc] initWithString:gameObjects error:&error];
        } else {
            // Send a notification when the data failed to load
            NSDictionary *userInfo = @{@"event" : @"gameDataError", @"message" : [[SpilError LoadFailed:@"Game Object container is empty!"] toJson]};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
            return nil;
        }
    }
    
    return nil;
}

-(Item*)getItem:(int)itemId {
    GameData *gameData = [self getGameData];

    if (gameData != nil) {
        for (int i = 0; i < [gameData.items count]; i++) {
            Item *item = [[gameData items] objectAtIndex:i];
            if (item.id == itemId) {
                return item;
            }
        }
        return nil;
    } else {
        // Send a notification when the item was not found
        NSDictionary *userInfo = @{@"event" : @"gameDataError", @"message" : [[SpilError ItemNotFound:@"No item data stored!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        return nil;
    }
}

-(Currency*)getCurrency:(int)id {
    GameData *gameData = [self getGameData];
    
    if (gameData != nil) {
        for (int i = 0; i < [gameData.currencies count]; i++) {
            Currency *currency = [[gameData currencies] objectAtIndex:i];
            if (currency.id == id) {
                return currency;
            }
        }
        return nil;
    } else {
        // Send a notification when the currency was not found
        NSDictionary *userInfo = @{@"event" : @"gameDataError", @"message" : [[SpilError CurrencyNotFound:@"Currency not found!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        return nil;
    }
}

-(Bundle*)getBundle:(int)bundleId {
    GameData *gameData = [self getGameData];
    
    if (gameData != nil) {
        for (int i = 0; i < [gameData.bundles count]; i++){
            Bundle *bundle = [[gameData bundles] objectAtIndex:i];
            if (bundle.id == bundleId){
                return bundle;
            }
        }
        return nil;
    } else {
        // Send a notification when the wallet was not found
        NSDictionary *userInfo = @{@"event" : @"gameDataError", @"message" : [[SpilError WalletNotFound:@"Wallet not found!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        return nil;
    }
}

//Exposed to SDK
-(void)updateGameData:(GameData*)gameData {
    NSString *jsonDataString = [gameData toJSONString];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:jsonDataString forKey:@"spilGameData"];
    [defaults synchronize];
}

-(NSString*)loadGameDataFromAssets {
    @try {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"defaultGameData" ofType:@"json"];
        NSStringEncoding encoding = NSUTF8StringEncoding;
        NSError *error;
        
        return [[NSString alloc] initWithContentsOfFile:filePath encoding:encoding error:&error];
    } @catch (NSException *exception) {
        NSLog(@"[GameDataController] loadGameDataFromAssets: %@",exception);
    }
    
    return @"";
}

-(NSString*)getShop {
    GameData *gameData = [self getGameData];
    
    if (gameData == nil) {
        // Send a notification when the gamedata was not found
        NSDictionary *userInfo = @{@"event" : @"gameDataError", @"message" : [[SpilError LoadFailed:@"GameData not found!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        return nil;
    }
    
    for (ShopTab *tab in [gameData shop]) {
        for(ShopEntry *entry in [tab entries]) {
            if ([self getBundle:entry.bundleId] == nil) {
                // Send a notification when there is no bundle for the entry (invalid shop data)
                NSDictionary *userInfo = @{@"event" : @"gameDataError", @"message" : [[SpilError LoadFailed:@"Shopdata not valid!"] toJson]};
                [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
                return @"";
            }
        }
    }
    
    //NSArray* jsonObjects = [ShopTab arrayOfDictionariesFromModels: [gameData shopTabs]];
    //return [JsonUtil convertObjectToJson:jsonObjects];
    return [[gameData shop] toJSONString];
}

-(NSString*)getShopPromotions {
    GameData *gameData = [self getGameData];
    
    if (gameData == nil) {
        // Send a notification when the gamedata was not found
        NSDictionary *userInfo = @{@"event" : @"gameDataError", @"message" : [[SpilError LoadFailed:@"GameData not found!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        return nil;
    }
    
    for (ShopPromotion *promotion in [gameData promotions]) {
        if ([self getBundle:promotion.bundleId] == nil) {
            // Send a notification when there is no bundle for the promotion (invalid shop data)
            NSDictionary *userInfo = @{@"event" : @"gameDataError", @"message" : [[SpilError LoadFailed:@"Promotion data not valid!"] toJson]};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
            return @"";
        }
    }
    
    return [[gameData promotions] toJSONString];
}

- (ShopPromotion*)getPromotion:(int)bundleId {
    GameData *gameData = [self getGameData];
    
    if (gameData == nil) {
        // Send a notification when the gamedata was not found
        NSDictionary *userInfo = @{@"event" : @"gameDataError", @"message" : [[SpilError LoadFailed:@"GameData not found!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        return nil;
    }
    
    for (ShopPromotion *promotion in [gameData promotions]) {
        if ([self getBundle:promotion.bundleId].id == bundleId) {
            NSDate *now = [NSDate date];
            NSDate *startDate = [Util parseDate: promotion.startDate];
            NSDate *endDate = [Util parseDate: promotion.endDate];
            if ([Util date:now isBetweenDate:startDate andDate:endDate]) {
                return promotion;
            }
        }
    }
    
    return nil;
}

@end
