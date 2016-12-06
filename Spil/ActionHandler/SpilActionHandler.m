//
//  SpilActionHandler.m
//  trackerSample
//
//  Created by Martijn van der Gun on 5/28/15.
//  Copyright (c) 2015 Martijn van der Gun. All rights reserved.
//

#import "SpilActionHandler.h"
#import "SpilEventTracker.h"
#import "SpilConfigHandler.h"
#import "SpilPackageHandler.h"
#import "GameDataController.h"
#import "PlayerDataController.h"
#import "Wallet.h"
#import "Inventory.h"
#import "JsonUtil.h"
#import "SpilUserHandler.h"
#import "SpilError.h"
#import "NotificationUtil.h"
#import "SpilAdvertisementHandler.h"

@implementation SpilActionHandler

+ (SpilActionHandler*)sharedInstance {
    static SpilActionHandler *spilActionHandler = nil;
    if (spilActionHandler == nil) {
        // structure used to test whether the block has completed or not
        static dispatch_once_t p;
        dispatch_once(&p, ^{
            spilActionHandler = [[SpilActionHandler alloc] init];
        });
    }
    return spilActionHandler;
}

- (UIViewController*)topMostController {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

+(void)handleAction:(NSDictionary*)action withCallBackUID:(NSString*)callbackUID{
    [self handleAction:action withCallBackUID:callbackUID orWithResponse:nil];
}

+(void)handleAction:(NSDictionary*)action withResponse:(void (^)(id response))block{
    [self handleAction:action withCallBackUID:nil orWithResponse:block];
}

+(void)handleAction:(NSDictionary*)action withCallBackUID:(NSString*)callbackUID orWithResponse:(void (^)(id response))block {
    BOOL hasCallbackUID = false;
    BOOL hasResponse = false;
    if(callbackUID != nil) hasCallbackUID = true;
    if(block != nil) hasResponse = true;

    // Error handling
    if (action == nil || action == NULL || action == 0 || action == false || !action || [[NSString stringWithFormat:@"%@",action] isEqualToString:@"0"]) {
        return;
    }
    
    //NSLog(@"[SpilActionHandler] handleAction %@ type: %@, action: %@ callback: %@",action, action[@"type"], action[@"action"], callbackUID);
    
    // TODO: temp to handle the splash screen not available, is not needed anymore when slot handles it correctly through the action.
    if([action objectForKey:@"action"] == nil ) {
        if ([action[@"name"] isEqualToString:@"requestSplashscreen"]) {
            [NotificationUtil send:@"splashScreenNotAvailable"];
        }
        return;
    }
    
    // Handle returned game data
    /*if([action[@"name"] isEqualToString:@"requestGameData"] && [action[@"type"] isEqualToString:@"gameData"]) {
        NSLog(@"[SpilActionHandler] Handle downloaded game data %@", [JsonUtil convertObjectToJson:action[@"data"]]);
        NSDictionary *jsonConfig = action[@"data"];
        
        [[GameDataController sharedInstance] processGameData:jsonConfig];
        
        // Load the player data
        [[PlayerDataController sharedInstance] requestPlayerData];
    }
    
    // Handle returned player data
    if([action[@"name"] isEqualToString:@"requestPlayerData"] && [action[@"type"] isEqualToString:@"playerData"]) {
        NSLog(@"[SpilActionHandler] Handle downloaded player data %@", [JsonUtil convertObjectToJson:action[@"data"]]);
        
        NSDictionary *jsonConfig = action[@"data"];
        NSError *error = nil;
        Wallet *wallet = [[Wallet alloc] initWithDictionary:jsonConfig[@"wallet"] error:&error];
        Inventory *inventory = [[Inventory alloc] initWithDictionary:jsonConfig[@"inventory"] error:&error];
        [[PlayerDataController sharedInstance] processPlayerData:wallet withInventory:inventory];
    }
    
    // Handle updated player data
    if([action[@"name"] isEqualToString:@"updatePlayerData"] && [action[@"type"] isEqualToString:@"playerData"]) {
        NSLog(@"[SpilActionHandler] Handle downloaded player data %@", [JsonUtil convertObjectToJson:action[@"data"]]);
        NSDictionary *jsonConfig = action[@"data"];
        NSError *error = nil;
        Wallet *walletChanges = [[Wallet alloc] initWithDictionary:jsonConfig[@"wallet"] error:&error];
        Inventory *inventoryChanges = [[Inventory alloc] initWithDictionary:jsonConfig[@"inventory"] error:&error];
        [[PlayerDataController sharedInstance] processPlayerData:walletChanges withInventory:inventoryChanges];
    }*/
    
    // Show advertisements
    if([action[@"type"] isEqualToString:@"advertisement"]) {
        if([action[@"action"] isEqualToString:@"show"]) {
            @try {
                if([action[@"data"] valueForKey:@"provider"] != nil) {
                    
                    NSLog(@"[SpilActionHandler] action show advertisement %@", action[@"data"]);
                    
                    NSString *provider = action[@"data"][@"provider"];
                    if([action[@"data"][@"adType"] isEqualToString:@"rewardVideo"]) {
                        // TODO: Currently app lovin is only supported
                        [[SpilAdvertisementHandler sharedInstance] checkRewardVideoAvailability:ADPROVIDER_APPLOVIN];
                    }
                    if([action[@"data"][@"adType"] isEqualToString:@"interstitial"]) {
                        // TODO: Currently app lovin is only supported
                        [[SpilAdvertisementHandler sharedInstance] showInterstitial:ADPROVIDER_APPLOVIN];
                    }
                }
            }
            @catch (NSException *exception) {
                NSLog(@"[SpilActionHandler] advertisement show Exception:%@",exception);
            }
        }
    }
    
    // Handle returned game configurations
    if([action[@"type"] isEqualToString:@"gameConfig"]) {
        NSLog(@"[SpilActionHandler] Handle downloaded game config %@", [JsonUtil convertObjectToJson:action[@"data"]]);
        NSString *jsonConfig = action[@"data"];
        [[SpilConfigHandler sharedInstance] storeConfig:jsonConfig];
    }
    
    // Handle returned store packages
    if([action[@"type"] isEqualToString:@"packages"]) {
        NSLog(@"[SpilActionHandler] Handle downloaded store packages %@", [JsonUtil convertObjectToJson:action[@"data"]]);
        NSDictionary *data = action[@"data"];
        [[SpilPackageHandler sharedInstance] storePackages:data];
    }
    
    // Handle game state
    if([action[@"type"] isEqualToString:@"gameState"] && action[@"action"] != (NSString *)[NSNull null]) {
        if ([action[@"action"] isEqualToString:@"update"]) {
            NSLog(@"[SpilActionHandler] Handle game state response %@", [JsonUtil convertObjectToJson:action[@"data"]]);
            NSDictionary *data = action[@"data"];
            NSString *privateData = @"";
            NSString *publicData = @"";
            for (NSDictionary *dict in data[@"gameStates"]) {
                if ([dict[@"access"] isEqualToString:@"public"]) {
                    publicData = dict[@"data"];
                } else if ([dict[@"access"] isEqualToString:@"private"]) {
                    privateData = dict[@"data"];
                }
            }
            [[SpilUserHandler sharedInstance] gameStateUpdateReceived:privateData public:publicData];
        } else if ([action[@"action"] isEqualToString:@"otherUsers"]) {
            NSLog(@"[SpilActionHandler] Handle friends game state response %@", [JsonUtil convertObjectToJson:action[@"data"]]);
            NSDictionary *data = action[@"data"];
            NSString *provider = data[@"provider"];
            NSDictionary *gameStates = data[@"gameStates"]; // Dict<UserId,GameState>
            [[SpilUserHandler sharedInstance] friendsGameStateLoaded:gameStates provider:provider];
        }
    }
    
    // handle daily login bonus
    if([action[@"type"] isEqualToString:@"reward"] && [action[@"action"] isEqualToString:@"collect"]) {
        NSDictionary *data = action[@"data"];
        NSLog(@"Daily login bonus collect response: %@", data);
        
        NSArray *collectibles = data[@"collectibles"];
        if (collectibles != nil) {
            NSMutableArray *externalItems = [NSMutableArray array];
            for (NSDictionary *collectible in collectibles) {
                id identifier = collectible[@"id"];
                NSString *type = collectible[@"type"];
                NSNumber *amount = collectible[@"amount"];
                
                if ([type isEqualToString:@"CURRENCY"]) {
                    int currencyId = (int)[identifier integerValue];
                    [[PlayerDataController sharedInstance] updateWallet:currencyId withDelta:[amount intValue] withReason:@"Daily Bonus From Client"];
                } else if ([type isEqualToString:@"ITEM"]) {
                    int itemId = (int)[identifier integerValue];
                    [[PlayerDataController sharedInstance] updateInventoryWithItem:itemId withAmount:[amount intValue] withAction:@"add" withReason:@"Daily Bonus From Client"];
                } else if ([type isEqualToString:@"EXTERNAL"]) {
                    NSString *externalId = collectible[@"id"];
                    NSDictionary *externalItem = @{ @"externalId" : externalId,
                                                    @"type" : type,
                                                    @"amount" : amount };
                    [externalItems addObject:externalItem];
                }
            }
            
            if ([externalItems count] > 0) {
                [NotificationUtil send:@"dailyBonusReward" data:externalItems];
            }
        }
    } else if([action[@"type"] isEqualToString:@"reward"] && [action[@"action"] isEqualToString:@"error"] && action[@"message"] != nil) {
        NSString *message = action[@"message"];
        [NotificationUtil send:@"dailyBonusError" message:[[SpilError WebServerError:message] toJson]];
    }
    
    // always return the response to unity
    if(hasResponse) {
        block(action);
    }
}

@end
