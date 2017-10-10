//
//  SpilActionHandler.m
//  trackerSample
//
//  Created by Martijn van der Gun on 5/28/15.
//  Copyright (c) 2015 Martijn van der Gun. All rights reserved.
//

#import "SpilActionHandler.h"
#if TARGET_OS_IOS
#import "SpilWebViewController.h"
#endif
#import "SpilEventTracker.h"
#import "SpilAdvertisementHandler.h"
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
    
    // Handle the splash screen not available, is not needed anymore when slot handles it correctly through the action.
    if([action objectForKey:@"action"] == nil ) {
        if ([action[@"name"] isEqualToString:@"requestSplashscreen"]) {
            [NotificationUtil send:@"splashScreenNotAvailable"];
        }
        return;
    }
    
    // Handle advertisement init
    #if TARGET_OS_IOS
    if([action[@"type"] isEqualToString:@"advertisement"]) {
        
    }
    
    // Show advertisements
    if([action[@"type"] isEqualToString:@"advertisement"]) {
        if([action[@"action"] isEqualToString:@"show"]) {

        }
    }
    #else
    // Show advertisements for tvos
    if([action[@"type"] isEqualToString:@"advertisement"]) {
    
    }
    #endif

    
    // Handle returned game data
    if([action[@"name"] isEqualToString:@"requestGameData"] && [action[@"type"] isEqualToString:@"gameData"]) {
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
        Wallet *wallet = [[Wallet alloc] initWithDictionary:jsonConfig[@"wallet"]];
        Inventory *inventory = [[Inventory alloc] initWithDictionary:jsonConfig[@"inventory"]];
        [[PlayerDataController sharedInstance] processPlayerData:wallet withInventory:inventory];
    }
    
    // Handle updated player data
    if([action[@"name"] isEqualToString:@"updatePlayerData"] && [action[@"type"] isEqualToString:@"playerData"]) {
        NSLog(@"[SpilActionHandler] Handle downloaded player data %@", [JsonUtil convertObjectToJson:action[@"data"]]);
        NSDictionary *jsonConfig = action[@"data"];
        Wallet *walletChanges = [[Wallet alloc] initWithDictionary:jsonConfig[@"wallet"]];
        Inventory *inventoryChanges = [[Inventory alloc] initWithDictionary:jsonConfig[@"inventory"]];
        [[PlayerDataController sharedInstance] processPlayerData:walletChanges withInventory:inventoryChanges];
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
    
    // webview action show
    if([action[@"type"] isEqualToString:@"overlay"]) {
        NSString *actionName = action[@"name"];
        if ([action[@"action"] isEqualToString:@"show"]) {
            NSLog(@"[SpilActionHandler] matched action");
            if(hasCallbackUID) {
                NSDictionary *data = action[@"data"];
                [[SpilActionHandler sharedInstance] showWebview:data withCallBackUID:callbackUID withActionName:actionName];
                return;
            }
        } else if ([action[@"action"] isEqualToString:@"notAvailable"]) {
            if ([actionName isEqualToString:@"splashscreen"]) {
                [NotificationUtil send:@"splashScreenNotAvailable"];
            } else if ([actionName isEqualToString:@"dailybonus"]) {
                [NotificationUtil send:@"dailyBonusNotAvailable"];
            }
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
                    [[PlayerDataController sharedInstance] updateWallet:currencyId withDelta:[amount intValue] withReason:@"Daily Bonus From Client" withLocation:@"DailyBonus"];
                } else if ([type isEqualToString:@"ITEM"]) {
                    int itemId = (int)[identifier integerValue];
                    [[PlayerDataController sharedInstance] updateInventoryWithItem:itemId withAmount:[amount intValue] withAction:@"add" withReason:@"Daily Bonus From Client" withLocation:@"DailyBonus"];
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

-(void)showWebview:(NSDictionary*)data withCallBackUID:(NSString*)callbackUID withActionName:(NSString*)name {
    #if TARGET_OS_IOS
    SpilWebViewController *webview = [[SpilWebViewController alloc] init];
    webview.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    webview.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [[[SpilActionHandler sharedInstance] topMostController] presentViewController:webview animated:YES completion:^() {
        NSMutableDictionary *options = [[NSMutableDictionary alloc] initWithDictionary:data];
        [options setObject:callbackUID forKey:@"callbackUID"];
        [webview setupWebview:options withActionName:name];
    }];
    #endif
}

@end
