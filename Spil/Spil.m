//
//  Spil.m
//  Spil
//
//  Created by Martijn van der Gun on 10/1/15.
//  Copyright © 2015 Spil Games. All rights reserved.
//

#import "Spil.h"
#import "SpilEventTracker.h"
#import "SpilAnalyticsHandler.h"
#import "SpilConfigHandler.h"
#import "SpilPackageHandler.h"
#import "UserProfile.h"
#import "GameDataController.h"
#import "PlayerDataController.h"
#import "GameDataController.h"
#import "GameData.h"
#import "JsonUtil.h"
#import "SpilUserHandler.h"
#import "SpilActionHandler.h"
#import "NSString+Extensions.h"
#import "AppLovinAdProvider.h"
#import "SpilAdvertisementHandler.h"

// C classes
#include "HookBridge.h"
#include <objc/runtime.h>

// Automatically link required frameworks on the fly when using a Dynamic framework. This will work from the parent app and prevent the need for external developers to include these framworks manually
@import StoreKit;
@import SystemConfiguration;
@import MediaPlayer;
@import CoreGraphics;
@import CoreLocation;
@import AdSupport;
@import QuartzCore;
@import AudioToolbox;
@import AVFoundation;
@import CoreMedia;
@import MediaPlayer;
@import MapKit;

@implementation Spil

@synthesize delegate;
BOOL disableAutoPushNotificationRegistration = false;

static Spil* sharedInstance;
+ (Spil*)sharedInstance {
    static Spil *spil = nil;
    if (spil == nil) {
        static dispatch_once_t p;
        dispatch_once(&p, ^{
            spil = [[Spil alloc] init];
        });
    }
    return spil;
}

-(id)init {
    self = [super init];
    
    // Register for internal Spil SDK notifications
    [[NSNotificationCenter defaultCenter] addObserverForName:@"spilNotificationHandler" object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [self spilNotificationHandler:note];
    }];
    
    return self;
}

// Handle internal Spil SDK notifications
-(void)spilNotificationHandler:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    if(userInfo != nil){
        NSString *event = userInfo[@"event"];
        NSDictionary *data = userInfo[@"data"];
        
        // Ad events
        if([event isEqualToString:@"adAvailable"]) {
            if ([delegate respondsToSelector:@selector(adAvailable:)]) {
                [delegate adAvailable:data[@"type"]];
            }
        }
        if([event isEqualToString:@"adNotAvailable"]) {
            if ([delegate respondsToSelector:@selector(adNotAvailable:)]) {
                [delegate adNotAvailable:data[@"type"]];
            }
        }
        if([event isEqualToString:@"adStart"]) {
            if ([delegate respondsToSelector:@selector(adStart)]) {
                [delegate adStart];
            }
        }
        if([event isEqualToString:@"adFinished"]){
            if ([delegate respondsToSelector:@selector(adFinished: reason: reward: network:)]) {
                [delegate adFinished:data[@"type"] reason:data[@"reason"] reward:[JsonUtil convertObjectToJson:data[@"reward"]] network:data[@"network"]];
            }
        }
        if([event isEqualToString:@"openParentalGate"]) {
            if ([delegate respondsToSelector:@selector(openParentalGate)]) {
                [delegate openParentalGate];
            }
        }
        
        if([event isEqualToString:@"notificationReward"]){
            if ([delegate respondsToSelector:@selector(grantReward:)]) {
                [delegate grantReward:userInfo];
            }
        }
        
        if([event isEqualToString:@"configUpdated"]){
            if ([delegate respondsToSelector:@selector(configUpdated)]) {
                [delegate configUpdated];
            }
            
            // When a new config is loaded also try to init other services again
            [[SpilAnalyticsHandler sharedInstance] initializeAnalyticsProviders];
            
            // Forward to unity
            [Spil sendMessage:@"ConfigUpdated" toObject:@"SpilSDK" withString:@""];
        }
        
        if([event isEqualToString:@"packagesLoaded"]){
            if ([delegate respondsToSelector:@selector(packagesLoaded)]) {
                [delegate packagesLoaded];
            }
        }
        
        // Game data events
        if([event isEqualToString:@"spilGameDataAvailable"]){
            if ([delegate respondsToSelector:@selector(spilGameDataAvailable)]) {
                // Call delegate method
                [delegate spilGameDataAvailable];
            }
            // Forward to unity
            [Spil sendMessage:@"SpilGameDataAvailable" toObject:@"SpilSDK" withString:@""];
        }
        if([event isEqualToString:@"spilGameDataError"]){
            if ([delegate respondsToSelector:@selector(spilGameDataError:)]) {
                // Call delegate method
                [delegate playerDataError:userInfo[@"message"]];
            }
            // Forward to unity
            [Spil sendMessage:@"SpilGameDataError" toObject:@"SpilSDK" withString:userInfo[@"message"]];
        }
        
        // Player data events
        if([event isEqualToString:@"playerDataAvailable"]){
            if ([delegate respondsToSelector:@selector(playerDataAvailable)]) {
                // Call delegate method
                [delegate playerDataAvailable];
            }
            // Forward to unity
            [Spil sendMessage:@"PlayerDataAvailable" toObject:@"SpilSDK" withString:@""];
        }
        if([event isEqualToString:@"playerDataError"]){
            if ([delegate respondsToSelector:@selector(playerDataError:)]) {
                // Call delegate method
                [delegate playerDataError:userInfo[@"message"]];
            }
            // Forward to unity
            [Spil sendMessage:@"PlayerDataError" toObject:@"SpilSDK" withString:userInfo[@"message"]];
        }
        if([event isEqualToString:@"playerDataUpdated"]){
            if ([delegate respondsToSelector:@selector(playerDataUpdated:updatedData:)]) {
                // Call delegate method
                [delegate playerDataUpdated:userInfo[@"reason"] updatedData:[JsonUtil convertObjectToJson:userInfo[@"updatedData"]]];
            }
            
            // Forward to unity
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            [data setObject:userInfo[@"reason"] forKey:@"reason"];
            [data setObject:userInfo[@"updatedData"][@"currencies"] forKey:@"currencies"];
            [data setObject:userInfo[@"updatedData"][@"items"] forKey:@"items"];
            [Spil sendMessage:@"PlayerDataUpdated" toObject:@"SpilSDK" withString:[JsonUtil convertObjectToJson:data]];
        }
        
        if ([event isEqualToString:@"gameStateError"]) {
            if ([delegate respondsToSelector:@selector(gameStateError:)]) {
                // Call delegate method
                [delegate gameStateError:userInfo[@"message"]];
            }
            // Forward to unity
            [Spil sendMessage:@"GameStateError" toObject:@"SpilSDK" withString:userInfo[@"message"]];
        }
        if ([event isEqualToString:@"gameStateUpdated"]) {
            if ([delegate respondsToSelector:@selector(gameStateUpdated:)]) {
                // Call delegate method
                [delegate gameStateUpdated:userInfo[@"access"]];
            }
            // Forward to unity
            [Spil sendMessage:@"GameStateUpdated" toObject:@"SpilSDK" withString:userInfo[@"access"]];
        }
        if ([event isEqualToString:@"otherUsersGameStateLoaded"]) {
            if ([delegate respondsToSelector:@selector(otherUsersGameStateLoaded:forProvider:)]) {
                // Call delegate method
                [delegate otherUsersGameStateLoaded:userInfo[@"data"] forProvider:userInfo[@"provider"]];
            }
            // Forward to unity
            [Spil sendMessage:@"OtherUsersGameStateLoaded" toObject:@"SpilSDK" withString:[JsonUtil convertObjectToJson:userInfo]];
        }

        
        // Splash screen events
        
        if ([event isEqualToString:@"splashScreenOpen"]) {
            if ([delegate respondsToSelector:@selector(splashScreenOpen)]) {
                // Call delegate method
                [delegate splashScreenOpen];
            }
            // Forward to unity
            [Spil sendMessage:@"SplashScreenOpen" toObject:@"SpilSDK" withString:@""];
        }
        if ([event isEqualToString:@"splashScreenNotAvailable"]) {
            if ([delegate respondsToSelector:@selector(splashScreenNotAvailable)]) {
                // Call delegate method
                [delegate splashScreenNotAvailable];
            }
            // Forward to unity
            [Spil sendMessage:@"SplashScreenNotAvailable" toObject:@"SpilSDK" withString:@""];
        }
        if ([event isEqualToString:@"splashScreenClosed"]) {
            if ([delegate respondsToSelector:@selector(splashScreenClosed)]) {
                // Call delegate method
                [delegate splashScreenClosed];
            }
            // Forward to unity
            [Spil sendMessage:@"SplashScreenClosed" toObject:@"SpilSDK" withString:@""];
        }
        if ([event isEqualToString:@"splashScreenOpenShop"]) {
            if ([delegate respondsToSelector:@selector(splashScreenOpenShop)]) {
                // Call delegate method
                [delegate splashScreenOpenShop];
            }
            // Forward to unity
            [Spil sendMessage:@"SplashScreenOpenShop" toObject:@"SpilSDK" withString:@""];
        }
        if ([event isEqualToString:@"splashScreenError"]) {
            if ([delegate respondsToSelector:@selector(splashScreenError:)]) {
                // Call delegate method
                [delegate splashScreenError:userInfo[@"message"]];
            }
            // Forward to unity
            [Spil sendMessage:@"SplashScreenError" toObject:@"SpilSDK" withString:[JsonUtil convertObjectToJson:userInfo[@"message"]]];
        }
        
        // Daily bonus events
        
        if ([event isEqualToString:@"dailyBonusOpen"]) {
            if ([delegate respondsToSelector:@selector(dailyBonusOpen)]) {
                // Call delegate method
                [delegate dailyBonusOpen];
            }
            // Forward to unity
            [Spil sendMessage:@"DailyBonusOpen" toObject:@"SpilSDK" withString:@""];
        }
        if ([event isEqualToString:@"dailyBonusNotAvailable"]) {
            if ([delegate respondsToSelector:@selector(dailyBonusNotAvailable)]) {
                // Call delegate method
                [delegate dailyBonusNotAvailable];
            }
            // Forward to unity
            [Spil sendMessage:@"DailyBonusNotAvailable" toObject:@"SpilSDK" withString:@""];
        }
        if ([event isEqualToString:@"dailyBonusClosed"]) {
            if ([delegate respondsToSelector:@selector(dailyBonusClosed)]) {
                // Call delegate method
                [delegate dailyBonusClosed];
            }
            // Forward to unity
            [Spil sendMessage:@"DailyBonusClosed" toObject:@"SpilSDK" withString:@""];
        }
        if ([event isEqualToString:@"dailyBonusReward"]) {
            if ([delegate respondsToSelector:@selector(dailyBonusReward:)]) {
                // Call delegate method
                [delegate dailyBonusReward:userInfo[@"data"]];
            }
            // Forward to unity
            [Spil sendMessage:@"DailyBonusReward" toObject:@"SpilSDK" withString:[JsonUtil convertObjectToJson:userInfo]];
        }
        if ([event isEqualToString:@"dailyBonusError"]) {
            if ([delegate respondsToSelector:@selector(dailyBonusError:)]) {
                // Call delegate method
                [delegate dailyBonusError:userInfo[@"message"]];
            }
            // Forward to unity
            [Spil sendMessage:@"DailyBonusError" toObject:@"SpilSDK" withString:userInfo[@"message"]];
        }
    }
}

#pragma mark General

+(void)start {
    [self startUsingUnity:false];
}

+(void)startWithOptions:(NSDictionary*)options{
    BOOL usingUnity = [options objectForKey:@"isUnity"] != nil && (BOOL)options[@"isUnity"];
    [self startUsingUnity:usingUnity];
}

+(void)startUsingUnity:(BOOL)usingUnity{
    NSLog(@"[SPIL] Initializing iOS Spil SDK v%@", SDK_VERSION);
    
    // Initialize the spil sharedinstance
    [Spil sharedInstance];
    
    [self detectStaging];
    
    [[SpilEventTracker sharedInstance] isUnity:usingUnity];

    // Start the tracker, no need to pass an appid yet
    [[SpilEventTracker sharedInstance] startWithAppId:@""];
    
    [self updateAppSettingsMenu];
    
    [self setAdvancedLoggingEnabled:NO];
}

+(NSString*)getSpilUserId {
    return [[SpilUserHandler sharedInstance] getUserId];
}

+(void)setPluginInformation:(NSString*)pluginName pluginVersion:(NSString*)pluginVersion {
    [[SpilEventTracker sharedInstance] setPluginInformation:pluginName pluginVersion:pluginVersion];
}

+(void)setAdvancedLoggingEnabled:(BOOL)advancedLoggingEnabled{
    [[SpilEventTracker sharedInstance] setAdvancedLogging:advancedLoggingEnabled];
}

+(void)log:(NSString *)message {
    NSLog(@"[SPIL-ExternalLog] %@", message);
}

+(void)setCustomBundleId:(NSString*)bundleId {
    [[SpilEventTracker sharedInstance] setCustomBundleId:bundleId];
}

+(void)detectStaging{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString *password = [defaults stringForKey:@"spil_password"];
    Boolean stagingMode = [defaults boolForKey:@"spil_usingstaging"];
    if ([password isEqualToString:@"sp1l"] && stagingMode == YES) {
        [[SpilEventTracker sharedInstance] staging:YES];
    }
}

+(void)updateAppSettingsMenu{
    NSUserDefaults* standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:[[SpilUserHandler sharedInstance] getUserId] forKey:@"spil_uid"];
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
    [standardUserDefaults setObject:[NSString stringWithFormat:@" %@ (%@)", version, build] forKey:@"spil_appversion"];
    [standardUserDefaults setObject:SDK_VERSION forKey:@"spil_apiversion"];
    
    [standardUserDefaults synchronize];
}

#pragma mark Event tracking

+(void)trackIAPPurchasedEvent:(NSString*)skuId transactionId:(NSString*)transactionId purchaseDate:(NSString*)purchaseDate {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"skuId"] = skuId;
    params[@"transactionId"] = transactionId;
    params[@"purchaseDate"] = purchaseDate;
    [[SpilEventTracker sharedInstance] trackEvent:@"iapPurchased" withParameters:params];
}

+(void)trackIAPRestoredEvent:(NSString*)skuId originalTransactionId:(NSString*)originalTransactionId originalPurchaseDate:(NSString*)originalPurchaseDate {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"skuId"] = skuId;
    params[@"originalTransactionId"] = originalTransactionId;
    params[@"originalPurchaseDate"] = originalPurchaseDate;
    [[SpilEventTracker sharedInstance] trackEvent:@"iapRestored" withParameters:params];
}

+(void)trackIAPFailedEvent:(NSString*)skuId error:(NSString*)error {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"skuId"] = skuId;
    params[@"error"] = error;
    [[SpilEventTracker sharedInstance] trackEvent:@"iapFailed" withParameters:params];
}

+(void)trackWalletInventoryEvent:(NSString*)currencyList itemsList:(NSString*)itemsList reason:(NSString*)reason location:(NSString*)location {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSArray *currencies = [JsonUtil convertStringToObject:currencyList];
    params[@"wallet"] = @{@"currencies": currencies};
    NSArray *items = [JsonUtil convertStringToObject:itemsList];
    params[@"items"] = items;
    params[@"reason"] = reason;
    params[@"location"] = location;
    params[@"trackingOnly"] = [NSNumber numberWithBool:true];
    [[SpilEventTracker sharedInstance] trackEvent:@"updatePlayerData" withParameters:params];
}

+(void)trackMilestoneEvent:(NSString*)name {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"name"] = name;
    [[SpilEventTracker sharedInstance] trackEvent:@"milestoneAchieved" withParameters:params];
}

+(void)trackLevelStartEvent:(NSString*)level {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"level"] = level;
    [[SpilEventTracker sharedInstance] trackEvent:@"levelStart" withParameters:params];
}

+(void)trackLevelCompleteEvent:(NSString*)level score:(NSString*)score stars:(NSString*)stars turns:(NSString*)turns {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"level"] = level;
    if(score != nil) {
        params[@"score"] = score;
    }
    if(stars != nil) {
        params[@"stars"] = stars;
    }
    if(turns != nil) {
        params[@"turns"] = turns;
    }
    [[SpilEventTracker sharedInstance] trackEvent:@"levelComplete" withParameters:params];
}

+(void)trackLevelFailed:(NSString*)level score:(NSString*)score turns:(NSString*)turns {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"level"] = level;
    if(score != nil) {
        params[@"score"] = score;
    }
    if(turns != nil) {
        params[@"turns"] = turns;
    }
    [[SpilEventTracker sharedInstance] trackEvent:@"levelFailed" withParameters:params];
}

+(void)trackTutorialCompleteEvent {
    [[SpilEventTracker sharedInstance] trackEvent:@"tutorialComplete"];
}

+(void)trackTutorialSkippedEvent {
    [[SpilEventTracker sharedInstance] trackEvent:@"tutorialSkipped"];
}

+(void)trackRegisterEvent:(NSString*)platform {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"platform"] = platform;
    [[SpilEventTracker sharedInstance] trackEvent:@"register" withParameters:params];
}

+(void)trackShareEvent:(NSString*)platform {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"platform"] = platform;
    [[SpilEventTracker sharedInstance] trackEvent:@"share" withParameters:params];
}

+(void)trackInviteEvent:(NSString*)platform {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"platform"] = platform;
    [[SpilEventTracker sharedInstance] trackEvent:@"invite" withParameters:params];
}

+(void)trackEvent:(NSString*)name{
    [[SpilEventTracker sharedInstance] trackEvent:name];
}

+(void)trackEvent:(NSString*)name withParameters:(NSDictionary *)params{
    [[SpilEventTracker sharedInstance] trackEvent:name withParameters:params];
}

+(void)trackEvent:(NSString*)name onResponse:(void (^)(id response))block{
    [[SpilEventTracker sharedInstance] trackEvent:name onResponse:block];
}

+(void)trackEvent:(NSString*)name withParameters:(NSDictionary *)params onResponse:(void (^)(id response))block{
    [[SpilEventTracker sharedInstance] trackEvent:name withParameters:params onResponse:block];
}

#pragma mark App flow

+(void)applicationDidEnterBackground:(UIApplication *)application{
    [[SpilEventTracker sharedInstance] applicationDidEnterBackground:application];
}

+(void)applicationDidBecomeActive:(UIApplication *)application{
    
    NSLog(@"[SPIL] applicationDidBecomeActive");
    
    // Initialize all analytics providers before any events are being tracked
    [[SpilAnalyticsHandler sharedInstance] initializeAnalyticsProviders];
    
    // Forward the application did become active
    [[SpilEventTracker sharedInstance] applicationDidBecomeActive:application];
    
    // Always request a new config when a session starts
    [self trackEvent:@"requestConfig"];
    
    // Always request new store packages when a session starts
    [self trackEvent:@"requestPackages"];
    
    // Request a advertisement init
    [self trackEvent:@"advertisementInit"];
    
    // Request the game and player data
    [self requestGameData];
    
    // Request the user private user data
    [[SpilUserHandler sharedInstance] getMyGameState];
    
    // Initialize app lovin
    AppLovinAdProvider *appLovin = [[SpilAdvertisementHandler sharedInstance] getAppLovinAdProvider];
    [appLovin initialize:nil];
}

#pragma mark Send message

+ (void) sendMessage:(NSString*)messageName toObject:(NSString*)objectName withData:(id)data {
    @try {
        NSString *parameterString = [JsonUtil convertObjectToJson:data];
        //NSLog(@"[SPIL] sendMessage: %@ messageName: %@ parameterString: %@",objectName, messageName, parameterString);
        [HookBridge sendMessage:messageName toObject:objectName withParameter:parameterString];
    }
    @catch (NSException *exception) {
        NSLog(@"[SPIL] sendMessage json error:%@",exception);
    }
    @finally {
        
    }
}

+ (void) sendMessage:(NSString*)messageName toObject:(NSString*)objectName withString:(NSString*)parameterString{
    
    NSLog(@"[SPIL] sendMessage: %@ messageName: %@ parameterString: %@",objectName, messageName, parameterString);
    
    @try {
        [HookBridge sendMessage:messageName toObject:objectName withParameter:parameterString];
    }
    @catch (NSException *exception) {
        NSLog(@"[SPIL] HookBridge sendMessage Exception:%@",exception);
    }
    @finally {
        
    }
    
}

#pragma mark Config

+(NSDictionary*)getConfig{
    return [[SpilConfigHandler sharedInstance] getConfig];
}

+(id)getConfigValue:(NSString*)keyString{
    return [[SpilConfigHandler sharedInstance] getConfigValue:keyString];
}

#pragma mark Packages

+(NSArray*)getAllPackages{
    return [[SpilPackageHandler sharedInstance] getAllPackages];
}

+(NSDictionary*)getPackageByID:(NSString*)keyString{
    return [[SpilPackageHandler sharedInstance] getPackageByID:keyString];
}

+(NSArray*)getAllPromotions {
    return [[SpilPackageHandler sharedInstance] getAllPromotions];
}

+(NSDictionary*)getPromotionByID:(NSString*)keyString{
    return [[SpilPackageHandler sharedInstance] getPromotionByID:keyString];
}

+(void)requestPackages{
    return [[SpilPackageHandler sharedInstance] requestPackages];
}

#pragma mark Ads

+(void)showMoreApps{
}

+(void)playRewardVideo {
    [[SpilAdvertisementHandler sharedInstance] showRewardVideo];
}

+(BOOL)isAdProviderInitialized:(NSString*)identifier {
    return false;
}

+(void)showToastOnVideoReward:(BOOL)enabled{

}

+(void)closedParentalGate:(BOOL)pass{
}

#pragma mark UserData & GameData

+(void)requestGameData {
    [[GameDataController sharedInstance] requestGameData];
}

+(void)requestPlayerData {
    [[PlayerDataController sharedInstance] requestPlayerData];
}

+(void)updatePlayerData {
    [[PlayerDataController sharedInstance] updatePlayerData];
}

+(NSString*)getUserProfile {
    return [[[PlayerDataController sharedInstance] getUserProfile] toJSONString];
}

+(NSString*)getWallet {
    return [[PlayerDataController sharedInstance] getWallet];
}

+(NSString*)getSpilGameData {
    return [[[GameDataController sharedInstance] getGameData] toJSONString];
}

+(NSString*)getInventory {
    return [[PlayerDataController sharedInstance] getInventory];
}

+(NSString*)getShop {
    return [[GameDataController sharedInstance] getShop];
}

+(NSString*)getShopPromotions {
    return [[GameDataController sharedInstance] getShopPromotions];
}

+(void)addCurrencyToWallet:(int)currencyId withAmount:(int)amount withReason:(NSString*)reason {
    [[PlayerDataController sharedInstance] updateWallet:currencyId withDelta:amount withReason:reason];
}

+(void)subtractCurrencyFromWallet:(int)currencyId withAmount:(int)amount withReason:(NSString*)reason {
    [[PlayerDataController sharedInstance] updateWallet:currencyId withDelta:-amount withReason:reason];
}

+(void)addItemToInventory:(int)itemId withAmount:(int)amount withReason:(NSString*)reason {
    [[PlayerDataController sharedInstance] updateInventoryWithItem:itemId withAmount:amount withAction:@"add" withReason:reason];
}

+(void)subtractItemFromInventory:(int)itemId withAmount:(int)amount withReason:(NSString*)reason {
    [[PlayerDataController sharedInstance] updateInventoryWithItem:itemId withAmount:amount withAction:@"subtract" withReason:reason];
}

+(void)consumeBundle:(int)bundleId withReason:(NSString*)reason {
    [[PlayerDataController sharedInstance] updateInventoryWithBundle:bundleId withReason:reason];
}

#pragma mark Web

+(void)requestDailyBonus {
    [Spil trackEvent:@"requestDailyBonus"];
}

+(void)requestSplashScreen {
    [Spil trackEvent:@"requestSplashscreen"];
}

#pragma mark User data

+(NSString*)getUserId {
    return [[SpilUserHandler sharedInstance] getExternalUserId];
}

+(NSString*)getUserProvider {
    return [[SpilUserHandler sharedInstance] getExternalUserProvider];
}

+(void)setUserId:(NSString*)userId forProviderId:(NSString*)providerId {
    [[SpilUserHandler sharedInstance] setExternalUserId:userId forProviderId:providerId];
}

+(void)setPrivateGameState:(NSString*)privateData {
    [[SpilUserHandler sharedInstance] setPrivateGameState:privateData];
}

+(NSString*)getPrivateGameState {
    return [[SpilUserHandler sharedInstance] getPrivateGameState];
}

+(void)setPublicGameState:(NSString*)publicData {
    [[SpilUserHandler sharedInstance] setPublicGameState:publicData];
}

+(NSString*)getPublicGameState {
    return [[SpilUserHandler sharedInstance] getPublicGameState];
}

+(void)getOtherUsersGameState:(NSString*)provider userIds:(NSArray*)userIds {
    [[SpilUserHandler sharedInstance] getOtherUsersGameState:provider userIds:userIds];
}

#pragma test methods (dev)

+(void)devRequestAd:(NSString*)provider withAdType:(NSString*)adType withParentalGate:(BOOL)parentalGate {
    /*if ([adType isEqualToString:@"banner"]) {
        [Spil showBanner];
    } else {*/
    //}
}

+(void)devShowRewardVideo:(NSString*)adProvider {
    [[SpilAdvertisementHandler sharedInstance] showRewardVideo:adProvider];
}

+(void)devShowInterstitial:(NSString*)adProvider {
    [[SpilAdvertisementHandler sharedInstance] showInterstitial:adProvider];
}

+(void)devShowMoreApps:(NSString*)adProvider {
}

/*+(void)showBanner {
    GoogleAdProvider *dfp = [[SpilAdvertisementHandler sharedInstance] getAdProvider:ADPROVIDER_GOOGLE];
    [dfp showBanner];
}*/

@end
