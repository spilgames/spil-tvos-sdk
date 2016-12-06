//
//  PlayerDataController.m
//  Spil
//
//  Created by Frank Slofstra on 18/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "PlayerDataController.h"
#import "Wallet.h"
#import "Inventory.h"
#import "UserProfile.h"
#import "Bundle.h"
#import "SpilEventTracker.h"
#import "PlayerCurrency.h"
#import "GameDataController.h"
#import "BundlePrice.h"
#import "BundleItem.h"
#import "GameData.h"
#import "SpilError.h"

@implementation PlayerDataController

bool playerDataLoaded = false;
bool clientWalletUpdateAllowed = true;
NSTimer *clientWalletUpdateAllowedTimer;
NSString *latestWalletReason = @"";

static PlayerDataController* sharedInstance;
+ (PlayerDataController*)sharedInstance {
    static PlayerDataController *playerDataController = nil;
    if (playerDataController == nil) {
        static dispatch_once_t p;
        dispatch_once(&p, ^{
            playerDataController = [[PlayerDataController alloc] init];
        });
    }
    return playerDataController;
}

-(void)requestPlayerData {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *wallet = [NSMutableDictionary dictionary];
    [wallet setObject:[NSNumber numberWithInteger:0] forKey:@"offset"];
    [params setObject:wallet forKey:@"wallet"];
    
    NSMutableDictionary *inventory = [NSMutableDictionary dictionary];
    [inventory setObject:[NSNumber numberWithInteger:0] forKey:@"offset"];
    [params setObject:inventory forKey:@"inventory"];
    
    [[SpilEventTracker sharedInstance] trackEvent:@"requestPlayerData" withParameters:params];
}

-(void)updatePlayerData {
    [self sendUpdatePlayerDataEvent:[self getUserProfile] withBundle:nil withReason:@"update"];
}

//Exposed to SDK
-(void)processPlayerData:(Wallet*)updatedWallet withInventory:(Inventory*)updatedInventory {
    UserProfile *userProfile = [self getUserProfile];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL playerDataInitialized = [defaults objectForKey:@"playerDataInitialized"] != nil;

    if (userProfile != nil) {
        userProfile.wallet.logic = updatedWallet.logic;
        userProfile.inventory.logic = updatedInventory.logic;
        
        // Get the previous offsets
        int previousWalletOffset = userProfile.wallet.offset;
        int previousInventoryOffset = userProfile.inventory.offset;
        
        // Handle wallet changes
        if (previousWalletOffset < updatedWallet.offset) {
            if ([userProfile.wallet.logic isEqualToString:@"SERVER"]) {
                // Process updated currencies, just take over the values from the backend and reset the delta
                for (PlayerCurrency *updatedPlayerCurrency in updatedWallet.currencies) {
                    PlayerCurrency *currentPlayerCurrency = [userProfile.wallet getCurrency:updatedPlayerCurrency.id];
                    if (currentPlayerCurrency != nil) {
                        currentPlayerCurrency.currentBalance = updatedPlayerCurrency.currentBalance;
                        currentPlayerCurrency.delta = 0;
                    }
                }
            } else if ([userProfile.wallet.logic isEqualToString:@"CLIENT"] && playerDataInitialized) {
                for (PlayerCurrency *updatedPlayerCurrency in updatedWallet.currencies) {
                    PlayerCurrency *currentPlayerCurrency = [userProfile.wallet getCurrency:updatedPlayerCurrency.id];
                    if (currentPlayerCurrency == nil) {
                        continue;
                    }
                    
                    if (userProfile.wallet.offset == 0 && updatedWallet.offset != 0) {
                        // Take over the value from the backend when reinstalling
                        currentPlayerCurrency.currentBalance = updatedPlayerCurrency.currentBalance;
                    } else {
                        // v2 implementation
                        if (updatedPlayerCurrency.delta != 0) {
                            currentPlayerCurrency.currentBalance += updatedPlayerCurrency.delta;
                            if (currentPlayerCurrency.currentBalance < 0) {
                                currentPlayerCurrency.currentBalance = 0;
                            }
                        }
                    }
                }
            }
            
            userProfile.wallet.offset = updatedWallet.offset;
        }
        
        // Handle inventory changes
        if (previousInventoryOffset < updatedInventory.offset) {
            if ([userProfile.inventory.logic isEqualToString:@"SERVER"]) {
                // Process updated items, just take over the values from the backend and reset the delta
                for (PlayerItem *updatedPlayerItem in updatedInventory.items) {
                    PlayerItem *currentPlayerItem = [userProfile.inventory getItem:updatedPlayerItem.id];
                    if (currentPlayerItem != nil) {
                        currentPlayerItem.amount = currentPlayerItem.amount;
                        currentPlayerItem.delta = 0;
                    }
                }
            } else if ([userProfile.inventory.logic isEqualToString:@"CLIENT"] && playerDataInitialized) {
                for (PlayerItem *updatedPlayerItem in updatedInventory.items) {
                    PlayerItem *currentPlayerItem = [userProfile.inventory getItem:updatedPlayerItem.id];
                    if (currentPlayerItem == nil) {
                        continue;
                    }
                    
                    // v2 implementation
                    if (updatedPlayerItem.delta != 0) {
                        currentPlayerItem.amount += updatedPlayerItem.delta;
                        if (currentPlayerItem.amount < 0) {
                            currentPlayerItem.amount = 0;
                        }
                    }
                }
            }
            userProfile.inventory.offset = updatedInventory.offset;
        }
        
        // Store the data locally
        [self updateUserProfile:userProfile];
        
        // Check if the server data was updated by checking the offsets
        if(previousWalletOffset < updatedWallet.offset || previousInventoryOffset < updatedInventory.offset) {
            // Send update notification
            NSMutableDictionary *updatedData = [NSMutableDictionary dictionary];
            NSArray* itemObjects = [PlayerItem arrayOfDictionariesFromModels:updatedInventory.items];
            [updatedData setObject:itemObjects forKey:@"items"];
            NSArray* currencyObjects = [PlayerCurrency arrayOfDictionariesFromModels:updatedWallet.currencies];
            [updatedData setObject:currencyObjects forKey:@"currencies"];
            NSDictionary *userInfo = @{@"event" : @"playerDataUpdated", @"reason" : @"Server Update", @"updatedData" : updatedData};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        }
        
        // Send data available notification
        if (playerDataLoaded == false) {
            NSDictionary *userInfo = @{@"event" : @"playerDataAvailable"};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
            playerDataLoaded = true;
        }
    }
}

//Exposed to SDK
-(UserProfile*)getUserProfile {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userProfileString = [defaults objectForKey:@"spilUserProfile"];
    
    NSError *error = nil;
    UserProfile *userProfile = nil;
    if(userProfileString != nil) {
        userProfile = [[UserProfile alloc] initWithString:userProfileString error:&error];
    } else {
        userProfileString = [self loadPlayerDataFromAssets];
        
        if(userProfileString != nil){
            [defaults setObject:userProfileString forKey:@"spilUserProfile"];
            [defaults synchronize];
            userProfile = [[UserProfile alloc] initWithString:userProfileString error:&error];
        } else {
            // Send a notification when the data failed to load
            NSDictionary *userInfo = @{@"event" : @"playerDataError", @"message" : [[SpilError LoadFailed:@"User Profile is empty!"] toJson]};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
            return nil;
        }
    }
    
    if (userProfile != nil) {
        // Check for missing arrays
        if (userProfile.wallet.currencies == nil) {
            userProfile.wallet.currencies = [NSMutableArray<PlayerCurrency> array];
        }
        if (userProfile.inventory.items == nil) {
            userProfile.inventory.items = [NSMutableArray<PlayerItem> array];
        }
        
        // Add missing gamedata currencies
        NSArray *currencies = [[GameDataController sharedInstance] getGameData].currencies;
        if (currencies != nil) {
            for (Currency *currency in currencies) {
                PlayerCurrency *foundCurrency = nil;
                for (PlayerCurrency *playerCurrency in userProfile.wallet.currencies) {
                    if (currency.id == playerCurrency.id) {
                        foundCurrency = playerCurrency;
                        break;
                    }
                }
                if (foundCurrency != nil) {
                    foundCurrency.name = currency.name;
                } else {
                    [userProfile.wallet.currencies addObject:[[PlayerCurrency alloc] initWithCurrency:currency]];
                }
            }
        }
        
        // Add missing gamedata items
        NSArray *items = [[GameDataController sharedInstance] getGameData].items;
        if (items != nil) {
            for (Item *item in items) {
                PlayerItem *foundItem = nil;
                for (PlayerItem *playerItem in userProfile.inventory.items) {
                    if (item.id == playerItem.id) {
                        foundItem = playerItem;
                        break;
                    }
                }
                if (foundItem != nil) {
                    foundItem.name = item.name;
                } else {
                    [userProfile.inventory.items addObject:[[PlayerItem alloc] initWithItem:item]];
                }
            }
        }
    }
    
    return userProfile;
}

//Exposed to SDK
-(NSString*)getWallet {
    UserProfile *userProfile = [self getUserProfile];
    
    if(userProfile != nil){
        Wallet *wallet = userProfile.wallet;
        
        return [wallet toJSONString];
    } else {
        // Send a notification when the wallet was not found
        NSDictionary *userInfo = @{@"event" : @"playerDataError", @"message" : [[SpilError WalletNotFound:@"No wallet data stored!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        return nil;
    }
}

//Exposed to SDK
-(NSString*)getInventory {
    UserProfile *userProfile = [self getUserProfile];
    
    if(userProfile != nil){
        Inventory *inventory = userProfile.inventory;
        
        // Remove items with amount zero
        NSMutableArray *zeroItems = [NSMutableArray array];
        for (PlayerItem *playerItem in inventory.items) {
            if (playerItem.amount == 0)
                [zeroItems addObject:playerItem];
        }
        [inventory.items removeObjectsInArray:zeroItems];
        
        // Create the json to return
        NSString *json = [inventory toJSONString];
        
        // Add the zero amount items again
        [inventory.items addObjectsFromArray:zeroItems];
        
        // Return the json
        return json;
    } else {
        // Send a notification when the inventory was not found
        NSDictionary *userInfo = @{@"event" : @"playerDataError", @"message" : [[SpilError InventoryNotFound:@"No inventory data stored!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        return nil;
    }
}

-(void)clientWalletUpdateAllowedTimerFinished:(NSTimer*)timer {
    clientWalletUpdateAllowed = true;
}

//Exposed to SDK - Case 1 (see Gist https://gist.github.com/sebastian24/392bd6a37d6c09c4bec9a13cb0e1bf3a )
-(void)updateWallet:(int)currencyId withDelta:(int)delta withReason:(NSString*)reason {
    // Check for existing profile
    UserProfile *userProfile = [self getUserProfile];
    if(userProfile == nil){
        // Send a notification when the wallet was not found
        NSDictionary *userInfo = @{@"event" : @"playerDataError", @"message" : [[SpilError WalletNotFound:@"No wallet data stored!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        return;
    }
    
    // Check for enough currency
    PlayerCurrency *currency = [userProfile.wallet getCurrency:currencyId];
    if (currency == nil) {
        // Send a notification when there is no currency
        NSDictionary *userInfo = @{@"event" : @"playerDataError", @"message" : [[SpilError CurrencyNotFound:@"Currency not found!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        return;
    }
    if (currency.currentBalance + delta < 0) {
        // Send a notification when there is not enough currency
        NSDictionary *userInfo = @{@"event" : @"playerDataError", @"message" : [[SpilError NotEnoughCurrency:@"Not enough currency!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        return;
    }
    
    if ([userProfile.wallet.logic isEqualToString:@"CLIENT"]) {
        if (clientWalletUpdateAllowed) {
            // Adjust the values
            currency.delta += delta;
            currency.currentBalance += delta;
            
            // Send the data
            [self sendUpdatePlayerDataEvent:userProfile withBundle: nil withReason:reason];
            
            currency.delta = 0;
            
            // Save to shared prefs
            [self updateUserProfile:userProfile];
            
            // Schedule the next data send
            clientWalletUpdateAllowed = false;
            [clientWalletUpdateAllowedTimer invalidate];
            clientWalletUpdateAllowedTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(clientWalletUpdateAllowedTimerFinished:) userInfo:nil repeats:NO];
        } else if (![latestWalletReason isEqualToString:reason]) {
            [self sendUpdatePlayerDataEvent:userProfile withBundle: nil withReason:latestWalletReason];
            
            // Adjust the values
            currency.delta = delta;
            currency.currentBalance += delta;
            
            [self sendUpdatePlayerDataEvent:userProfile withBundle: nil withReason:reason];
            currency.delta = 0;
            
            // Save to shared prefs
            [self updateUserProfile:userProfile];
            
            clientWalletUpdateAllowed = false;
            [clientWalletUpdateAllowedTimer invalidate];
            clientWalletUpdateAllowedTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(clientWalletUpdateAllowedTimerFinished:) userInfo:nil repeats:NO];
        } else {
            // Adjust the values
            currency.delta += delta;
            currency.currentBalance += delta;
            
            // Save to shared prefs
            [self updateUserProfile:userProfile];
        }
        
        // Store the reason
        latestWalletReason = reason;
        
        // Send notification
        NSMutableDictionary *updatedData = [NSMutableDictionary dictionary];
        [updatedData setObject:@[] forKey:@"items"];
        
        NSMutableDictionary *dict = [[currency toDictionary] mutableCopy];
        [dict setObject:[NSNumber numberWithInt:delta] forKey:@"delta"];
        
        [updatedData setObject:@[dict] forKey:@"currencies"];
        NSDictionary *userInfo = @{@"event" : @"playerDataUpdated", @"reason" : reason, @"updatedData" : updatedData};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
    } else {
        // Adjust the values
        currency.delta += delta;
        currency.currentBalance += delta;
        
        // Send the changes to the server
        [self sendUpdatePlayerDataEvent:userProfile withBundle:nil withReason:reason];
        
        // Revert the changed values because it should be validated by the server first before setting it on the client side
        currency.delta -= delta;
        currency.currentBalance -= delta;
    }
}

//Exposed to SDK - Case 2 (see Gist https://gist.github.com/sebastian24/392bd6a37d6c09c4bec9a13cb0e1bf3a )
-(void)updateInventoryWithItem:(int)itemId withAmount:(int)amount withAction:(NSString*)action withReason:(NSString*)reason {
    // Check user profile
    UserProfile *userProfile = [self getUserProfile];
    if(userProfile == nil){
        // Send a notification when the inventory was not found
        NSDictionary *userInfo = @{@"event" : @"playerDataError", @"message" : [[SpilError InventoryNotFound:@"No inventory data stored!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        return;
    }
    
    // Check item
    PlayerItem *item = (PlayerItem*) [userProfile.inventory getItem:itemId];
    if(item == nil){
        // Send a notification when the item was not found
        NSDictionary *userInfo = @{@"event" : @"playerDataError", @"message" : [[SpilError ItemNotFound:@"Unknown item type!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        return;
    }
    
    // Calc delta and check if the amount/action is allowed
    int delta = amount;
    if ([action isEqualToString:@"subtract"]) {
        delta = -amount;
        if (item.amount - amount < 0) {
            // Send a notification when the item amount was to low
            NSDictionary *userInfo = @{@"event" : @"playerDataError", @"message" : [[SpilError ItemAmountToLow:@"Item amount to low!"] toJson]};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
            return;
        }
    }
    
    if ([userProfile.wallet.logic isEqualToString:@"CLIENT"]) {
        // Adjust the values
        item.delta += delta;
        item.amount += delta;
        
        // Send the data
        [self sendUpdatePlayerDataEvent:userProfile withBundle:nil withReason:reason];
        item.delta = 0;
        
        // Save to shared prefs
        [self updateUserProfile:userProfile];
        
        // Send notification
        NSMutableDictionary *updatedData = [NSMutableDictionary dictionary];
        
        NSMutableDictionary *dict = [[item toDictionary] mutableCopy];
        [dict setObject:[NSNumber numberWithInt:delta] forKey:@"delta"];
        
        [updatedData setObject:@[dict] forKey:@"items"];
        [updatedData setObject:@[] forKey:@"currencies"];
        NSDictionary *userInfo = @{@"event" : @"playerDataUpdated", @"reason" : reason, @"updatedData" : updatedData};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
    } else {
        // Adjust the values
        item.delta += delta;
        item.amount += delta;
        
        // Send the changes to the server
        [self sendUpdatePlayerDataEvent:userProfile withBundle:nil withReason:reason];
        
        // Revert the changed values because it should be validated by the server first before setting it on the client side
        item.delta -= delta;
        item.amount -= delta;
    }
}

//Exposed to SDK - Case 3 (see Gist https://gist.github.com/sebastian24/392bd6a37d6c09c4bec9a13cb0e1bf3a )
-(void)updateInventoryWithBundle:(int)bundleId withReason:(NSString*)reason {
    // Check user profile
    UserProfile *userProfile = [self getUserProfile];
    if(userProfile == nil){
        // Send a notification when the user profile was not found
        NSDictionary *userInfo = @{@"event" : @"playerDataError", @"message" : [[SpilError LoadFailed:@"User profile not found!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        return;
    }
    
    // Check bundle
    Bundle *bundle = [[GameDataController sharedInstance] getBundle:bundleId];
    if(bundle == nil){
        // Send a notification when the data bundle was not found
        NSDictionary *userInfo = @{@"event" : @"playerDataError", @"message" : [[SpilError BundleNotFound:@"Unknown bundle type!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        return;
    }
    
    // Check currencies
    BOOL enoughCurrency = [userProfile.wallet hasEnoughCurrencyForBundle:bundle];
    if (!enoughCurrency) {
        // Send a notification when there is not enough currency
        NSDictionary *userInfo = @{@"event" : @"playerDataError", @"message" : [[SpilError BundleNotFound:@"Not enough currency!"] toJson]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
        return;
    }
    
    // Update Player Currency
    for (BundlePrice *bundlePrice in bundle.prices) {
        PlayerCurrency *playerCurrency = [userProfile.wallet getCurrency:bundlePrice.currencyId];
        if (playerCurrency == nil) {
            continue;
        }
        
        if ([userProfile.wallet.logic isEqualToString:@"CLIENT"]) {
            int updatedBalance = playerCurrency.currentBalance - bundlePrice.value;
            playerCurrency.delta -= bundlePrice.value;
            playerCurrency.currentBalance = updatedBalance;
        } else {
            // TODO: add server logic
        }
    }
    
    // Check for a running promotion
    int multiplier = 1;
    ShopPromotion *promotion = [[GameDataController sharedInstance] getPromotion:bundleId];
    if (promotion != nil) {
        multiplier = promotion.amount;
    }
    
    // Update Player Inventory
    for (BundleItem *bundleItem in bundle.items) {
        PlayerItem *playerItem = [userProfile.inventory getItem:bundleItem.id];
        if (playerItem == nil) {
            continue;
        }
        
        if ([userProfile.wallet.logic isEqualToString:@"CLIENT"]) {
            int updatedAmount = playerItem.amount + (bundleItem.amount * multiplier);
            playerItem.delta += (bundleItem.amount * multiplier);
            playerItem.amount = updatedAmount;
        } else {
            // TODO: add server logic
        }
    }
    
    // Send the updated profile to the backend
    [self sendUpdatePlayerDataEvent:userProfile withBundle: bundle withReason:reason];
    
    // Reset the deltas
    for (BundlePrice *bundlePrice in bundle.prices) {
        PlayerCurrency *playerCurrency = [userProfile.wallet getCurrency:bundlePrice.currencyId];
        if (playerCurrency != nil) {
            playerCurrency.delta = 0;
        }
    }
    for (BundleItem *bundleItem in bundle.items) {
        PlayerItem *playerItem = [userProfile.inventory getItem:bundleItem.id];
        if (playerItem != nil) {
            playerItem.delta = 0;
        }
    }
    
    // Store the profile locally
    if ([userProfile.wallet.logic isEqualToString:@"CLIENT"]) {
        [self updateUserProfile:userProfile];
    } else {
        // TODO: add server logic
    }
    
    // Send notification
    NSMutableDictionary *updatedData = [NSMutableDictionary dictionary];
    NSArray* itemObjects = [PlayerItem arrayOfDictionariesFromModels:bundle.items];
    [updatedData setObject:itemObjects forKey:@"items"];
    NSArray* currencyObjects = [PlayerCurrency arrayOfDictionariesFromModels:bundle.prices];
    [updatedData setObject:currencyObjects forKey:@"currencies"];
    NSDictionary *userInfo = @{@"event" : @"playerDataUpdated", @"reason" : reason, @"updatedData" : updatedData};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
}

//Exposed to SDK
-(void)updateUserProfile:(UserProfile*)userProfile {
    NSLog(@"[PLAYERDATACONTROLLER] Writing to user defaults");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[userProfile toJSONString] forKey:@"spilUserProfile"];
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"playerDataInitialized"];
    [defaults synchronize];
}

-(NSString*)loadPlayerDataFromAssets {
    @try {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"defaultPlayerData" ofType:@"json"];
        
        NSStringEncoding encoding = NSUTF8StringEncoding;
        NSError *error;
        
        return [[NSString alloc] initWithContentsOfFile:filePath encoding:encoding error:&error];
    } @catch (NSException *exception) {
        NSLog(@"[PlayerDataController] loadPlayerDataFromAssets: %@",exception);
    }
    
    return @"";
}

-(void)sendUpdatePlayerDataEvent:(UserProfile*)userProfile withBundle:(Bundle*)bundle withReason:(NSString*)reason {
    NSMutableDictionary *requestData = [NSMutableDictionary dictionary];
    
    // Add wallet
    NSMutableDictionary *wallet = [NSMutableDictionary dictionary];
    if (![reason isEqualToString:@"update"]) {
        NSArray *updatedCurrencies = [userProfile.wallet getUpdatedCurrencies];
        if ([updatedCurrencies count] > 0) {
            [wallet setObject:updatedCurrencies forKey:@"currencies"];
        }
    }
    [wallet setObject:[NSNumber numberWithInteger:[userProfile wallet].offset] forKey:@"offset"];
    [requestData setObject:wallet forKey:@"wallet"];
    
    // Add inventory
    NSMutableDictionary *inventory = [NSMutableDictionary dictionary];
    if (![reason isEqualToString:@"update"]) {
        NSArray *updatedItems = [userProfile.inventory getUpdatedItems];
        if ([updatedItems count] > 0) {
            [inventory setObject:updatedItems forKey:@"items"];
        }
    }
    [inventory setObject:[NSNumber numberWithInteger:[userProfile inventory].offset] forKey:@"offset"];
    [requestData setObject:inventory forKey:@"inventory"];
    
    // Add bundle
    if (bundle != nil) {
        NSMutableDictionary *bundleObject = [NSMutableDictionary dictionary];
        [bundleObject setObject:[NSNumber numberWithInteger:bundle.id] forKey:@"id"];
        [requestData setObject:bundleObject forKey:@"bundle"];
    }
    
    // Add update metadata
    [requestData setObject:reason forKey:@"reason"];
    [[SpilEventTracker sharedInstance] trackEvent:@"updatePlayerData" withParameters:requestData];
}

@end
