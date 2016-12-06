//
//  HookBridge.cpp
//  SpilStaticLib
//
//  Created by Martijn van der Gun on 6/22/15.
//  Copyright (c) 2015 Martijn van der Gun. All rights reserved.
//

#import "HookBridge.h"

#import "SpilEventTracker.h"
#import "SpilActionHandler.h"
#import "Spil.h"
#import "SpilUserHandler.h"

#include <stdlib.h> 
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <mach-o/loader.h>

#include <dlfcn.h>

#import <stdlib.h>
#import <stdio.h>
#import <mach-o/dyld.h>
#import <mach-o/ldsyms.h>

@implementation HookBridge

+ (void) sendMessage:(NSString*)messageName toObject:(NSString*)objectName withParameter:(NSString*)parameterString{
    NSLog(@"[HookBridge] SendMessage to object: %@ with method: %@ with params: %@", objectName, messageName, parameterString);
    
    if([[SpilEventTracker sharedInstance] isUnity]) {
        @try {
            UnitySendMessage([objectName cStringUsingEncoding:NSUTF8StringEncoding],
                             [messageName cStringUsingEncoding:NSUTF8StringEncoding],
                             [parameterString cStringUsingEncoding:NSUTF8StringEncoding]);
            //NSLog(@"[HookBridge] UnitySendMessage, object: %@ method: %@ data: %@", objectName, messageName, parameterString);
        }
        @catch (NSException *exception) {
            NSLog(@"[HookBridge] UnitySendMessage, exception:%@",exception.reason);
        }
    }
}

char* cStringCopy(const char* string) {
    if (string == NULL) {
        return NULL;
    }
    char* res = (char*)malloc(strlen(string) + 1);
    strcpy(res, string);
    return res;
}

char* getSpilUserIdNative() {
    NSLog(@"[HookBridge] getSpilUserIdNative");
    
    NSString *uid = [[SpilUserHandler sharedInstance] getUserId];
    if (uid == nil) {
        uid = @"";
    }
    
    NSLog(@"[HookBridge] getSpilUserIdNative OUT: %@", uid);
    return cStringCopy([uid UTF8String]);
}

void setPluginInformationNative(const char* pluginName, const char* pluginVersion) {
    NSString *name = [NSString stringWithCString:pluginName encoding:NSUTF8StringEncoding];
    NSString *version = [NSString stringWithCString:pluginVersion encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] setPluginInformationNative IN pluginName: %@, pluginVersion: %@", name, version);
    
    [Spil setPluginInformation:name pluginVersion:version];
}

// --- Event tracking ---

void initEventTracker(){
    NSLog(@"[HookBridge] initEventTracker");
    
    [Spil start];
}

void initEventTrackerWithOptions(const char* options){
    NSString *json_string = [NSString stringWithUTF8String:options];
    NSLog(@"[HookBridge] initEventTrackerWithOptions IN options: %@", json_string);
    
    NSData *data = [json_string dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *optionsDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    [Spil startWithOptions:optionsDict];
}

void trackEventNative(const char* eventName){
    NSString *event = [NSString stringWithCString:eventName encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackEventNative IN eventName: %@", event);
    
    [[SpilEventTracker sharedInstance] trackEvent:event];
}

void trackEventWithParamsNative(const char* eventName, const char* jsonStringParams){
    NSString *event = [NSString stringWithCString:eventName encoding:NSUTF8StringEncoding];
    NSString *jsonNSStringParams = [NSString stringWithCString:jsonStringParams encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackEventWithParamsNative IN eventName: %@, jsonStringParams: %@", event, jsonNSStringParams);
    
    NSData *data = [jsonNSStringParams dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *params = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    [[SpilEventTracker sharedInstance] trackEvent:event withParameters:params];
}

void trackIAPPurchasedEvent(const char* skuId, const char* transactionId, const char* purchaseDate) {
    NSString *sku = [NSString stringWithCString:skuId encoding:NSUTF8StringEncoding];
    NSString *transaction = [NSString stringWithCString:transactionId encoding:NSUTF8StringEncoding];
    NSString *purchase = [NSString stringWithCString:transactionId encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackIAPPurchasedEvent IN skuId: %@, transactionId: %@, purchaseDate: %@", sku, transaction, purchase);
    [Spil trackIAPPurchasedEvent:sku transactionId:transaction purchaseDate:purchase];
}

void trackIAPRestoredEvent(const char* skuId, const char* originalTransactionId, const char* originalPurchaseDate) {
    NSString *sku = [NSString stringWithCString:skuId encoding:NSUTF8StringEncoding];
    NSString *originalTransaction = [NSString stringWithCString:originalTransactionId encoding:NSUTF8StringEncoding];
    NSString *originalPurchase = [NSString stringWithCString:originalPurchaseDate encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackIAPRestoredEvent IN skuId: %@, originalTransactionId: %@, originalPurchaseDate: %@", sku, originalTransaction, originalPurchase);
    [Spil trackIAPRestoredEvent:sku originalTransactionId:originalTransaction originalPurchaseDate:originalPurchase];
}

void trackIAPFailedEvent(const char* skuId, const char* error) {
    NSString *sku = [NSString stringWithCString:skuId encoding:NSUTF8StringEncoding];
    NSString *e = [NSString stringWithCString:error encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackIAPFailedEvent IN skuId: %@, error: %@", sku, e);
    [Spil trackIAPFailedEvent:sku error:e];
}

void trackWalletInventoryEvent(const char* currencyList, const char* itemsList, const char* reason, const char* location) {
    NSString *currency = [NSString stringWithCString:currencyList encoding:NSUTF8StringEncoding];
    NSString *items = [NSString stringWithCString:itemsList encoding:NSUTF8StringEncoding];
    NSString *r = [NSString stringWithCString:reason encoding:NSUTF8StringEncoding];
    NSString *l = [NSString stringWithCString:location encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackWalletInventoryEvent IN itemsList: %@, itemsList: %@, reason: %@, location: %@", currency, items, r, l);
    [Spil trackWalletInventoryEvent:currency itemsList:items reason:r location:l];
}

void trackMilestoneEvent(const char* name) {
    NSString *n = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackMilestoneEvent IN name: %@", n);
    [Spil trackMilestoneEvent:n];
}

void trackLevelStartEvent(const char* level) {
    NSString *l = [NSString stringWithCString:level encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackLevelStartEvent IN level: %@", l);
    [Spil trackLevelStartEvent:l];
}

void trackLevelCompleteEvent(const char* level, const char* score, const char* stars, const char* turns) {
    NSString *l = [NSString stringWithCString:level encoding:NSUTF8StringEncoding];
    NSString *s = [NSString stringWithCString:score encoding:NSUTF8StringEncoding];
    NSString *st = [NSString stringWithCString:stars encoding:NSUTF8StringEncoding];
    NSString *t = [NSString stringWithCString:turns encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackLevelCompleteEvent IN level: %@, score: %@, stars: %@, turns: %@", l, s, st, t);
    [Spil trackLevelCompleteEvent:l score:s stars:st turns:t];
}

void trackLevelFailed(const char* level, const char* score, const char* turns) {
    NSString *l = [NSString stringWithCString:level encoding:NSUTF8StringEncoding];
    NSString *s = [NSString stringWithCString:score encoding:NSUTF8StringEncoding];
    NSString *t = [NSString stringWithCString:turns encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackLevelFailed IN level: %@, score: %@, turns: %@", l, s, t);
    [Spil trackLevelFailed:l score:s turns:t];
}

void trackTutorialCompleteEvent() {
    NSLog(@"[HookBridge] trackTutorialCompleteEvent");
    [Spil trackTutorialCompleteEvent];
}

void trackTutorialSkippedEvent() {
    NSLog(@"[HookBridge] trackTutorialSkippedEvent");
    [Spil trackTutorialSkippedEvent];
}

void trackRegisterEvent(const char* platform) {
    NSString *p = [NSString stringWithCString:platform encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackRegisterEvent IN platform: %@", p);
    [Spil trackRegisterEvent:p];
}

void trackShareEvent(const char* platform) {
    NSString *p = [NSString stringWithCString:platform encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackShareEvent IN platform: %@", p);
    [Spil trackShareEvent:p];
}

void trackInviteEvent(const char* platform) {
    NSString *p = [NSString stringWithCString:platform encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackInviteEvent IN platform: %@", p);
    [Spil trackInviteEvent:p];
}

// --- App flow ---

void applicationDidFinishLaunchingWithOptions(const char* launchOptions) {

}

void applicationDidEnterBackground() {
    NSLog(@"[HookBridge] applicationDidEnterBackground");
    
    [Spil applicationDidEnterBackground:nil];
}

void applicationDidBecomeActive() {
    NSLog(@"[HookBridge] applicationDidBecomeActive");
    
    [Spil applicationDidBecomeActive:nil];
}

// --- Push Notifications ---

void disableAutomaticRegisterForPushNotificationsNative() {

}

void registerForPushNotifications() {
    NSLog(@"[HookBridge] registerForPushNotifications");
}

void setPushNotificationKey(const char* pushKey){
    NSString *pushK = [NSString stringWithCString:pushKey encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] setPushNotificationKey IN pushKey: %@", pushK);
    
    [[SpilEventTracker sharedInstance] setPushKey:pushK];
}

void handlePushNotification(const char* notificationStringParams){
    NSString *notificationNSStringParams = [NSString stringWithCString:notificationStringParams encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] handlePushNotification IN notificationStringParams: %@", notificationNSStringParams);
    
    NSData *data = [notificationNSStringParams dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *params = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    [SpilActionHandler handleAction:params withResponse:^(id response) {
        // send unity a message
        NSString *jsonString = [JsonUtil convertObjectToJson:response];
        [Spil sendMessage:@"OnResponseReceived" toObject:@"SpilSDK" withString:jsonString];
    }];
}

// -- Config ---

char* getConfigNative () {
    NSLog(@"[HookBridge] getConfigNative");

    NSDictionary *config = [Spil getConfig];
    NSString *jsonString = [JsonUtil convertObjectToJson:config];
    if (jsonString == nil) {
        jsonString = @"{}";
    }
    NSLog(@"[HookBridge] getConfigNative OUT: %@", jsonString);
    return cStringCopy([jsonString UTF8String]);
}

char* getConfigValueNative (const char* keyName) {
    NSString *key = [NSString stringWithCString:keyName encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] getConfigValueNative IN keyName: %@", key);
    
    id configValue = [Spil getConfigValue:key];
    NSString* result = @"{}";
    if(configValue != nil){
        if ([configValue isKindOfClass:[NSString class]]) {
            result = configValue;
        } else if ([configValue isKindOfClass:[NSNumber class]]) {
            result = [configValue stringValue];
        } else if([configValue isKindOfClass:[NSDictionary class]] || [configValue isKindOfClass:[NSArray class]]) {
            result = [JsonUtil convertObjectToJson:configValue];
        }
    }
    
    NSLog(@"[HookBridge] getConfigValueNative OUT: %@", result);
    return cStringCopy([result UTF8String]);
}

void setCustomBundleIdNative(const char* bundleId) {
    NSString *bid = [NSString stringWithCString:bundleId encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] setCustomBundleId IN bundleId: %@", bid);
    
    [Spil setCustomBundleId:bid];
}

// -- Packages & Promotions ---

void requestPackagesNative () {
    NSLog(@"[HookBridge] requestPackagesNative");
    
    [Spil requestPackages];
}

char* getPackageNative (const char* keyName) {
    NSString *key = [NSString stringWithCString:keyName encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] getPackageNative IN keyName: %@", key);
    
    NSDictionary *package = [Spil getPackageByID:key];
    
    NSString* json_string = @"{}";
    if(package == nil){
        char* s = cStringCopy([json_string UTF8String]);
        return s;
    } else if([[package allKeys] count] > 0){
        json_string = [JsonUtil convertObjectToJson:package];
        if (json_string == nil) {
            json_string = @"{}";
        }
    }
    
    NSLog(@"[HookBridge] getPackageNative OUT: %@", json_string);
    return cStringCopy([json_string UTF8String]);
}

char* getAllPackagesNative () {
    if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
        NSLog(@"[HookBridge] getAllPackagesNative");
    }
    
    NSArray *packages = [Spil getAllPackages];
    
    NSString* json_string = @"{}";
    if(packages == nil){
        char* s = cStringCopy([json_string UTF8String]);
        return s;
    } else if([packages count] > 0) {
        json_string = [JsonUtil convertObjectToJson:packages];
        if (json_string == nil) {
            json_string = @"{}";
        }
    }
    
    char* s = cStringCopy([json_string UTF8String]);
    return s;
}

char* getPromotionNative (const char* keyName) {
    if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled])  {
        NSLog(@"[HookBridge] getPromotionNative");
    }
    
    NSString *key = [NSString stringWithCString:keyName encoding:NSUTF8StringEncoding];
    NSDictionary *promotion = [Spil getPromotionByID:key];
    
    NSString* json_string = @"{}";
    if(promotion == nil){
        char* s = cStringCopy([json_string UTF8String]);
        return s;
    } else if([[promotion allKeys] count] > 0){
        json_string = [JsonUtil convertObjectToJson:promotion];
        if (json_string == nil) {
            json_string = @"{}";
        }
    }
    
    char* s = cStringCopy([json_string UTF8String]);
    return s;
}

// -- ADS ---

void showMoreAppsNative () {
    NSLog(@"[HookBridge] showMoreAppsNative");
    
    [Spil showMoreApps];
}

void playRewardVideoNative () {
    NSLog(@"[HookBridge] playRewardVideoNative");
    
    [Spil playRewardVideo];
}

void devRequestAdNative(const char* providerName, const char* adTypeName, const bool parentalGate) {
    NSString *provider = [NSString stringWithCString:providerName encoding:NSUTF8StringEncoding];
    NSString *adType = [NSString stringWithCString:adTypeName encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] devRequestAdNative IN providerName: %@, adTypeName: %@, parentalGate: %d", provider, adType, parentalGate);
    
    [Spil devRequestAd:provider withAdType:adType withParentalGate:parentalGate];
}

void devShowRewardVideoNative(const char* providerName) {
    NSString *provider = [NSString stringWithCString:providerName encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] devShowRewardVideoNative IN providerName: %@", provider);
    
    [Spil devShowRewardVideo:provider];
}

void devShowInterstitialNative(const char* providerName) {
    NSString *provider = [NSString stringWithCString:providerName encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] devShowInterstitialNative IN providerName: %@", provider);
    
    [Spil devShowInterstitial:provider];
}

void devShowMoreAppsNative(const char* providerName) {
    NSString *provider = [NSString stringWithCString:providerName encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] devShowMoreAppsNative IN providerName: %@", provider);
    
    [Spil devShowMoreApps:provider];
}

void showToastOnVideoReward(const bool enabled) {
    NSLog(@"[HookBridge] showToastOnVideoReward IN enabled: %d", enabled);
    
    [Spil showToastOnVideoReward:enabled];
}

void closedParentalGateNative(const bool pass) {
    NSLog(@"[HookBridge] closedParentalGate IN pass: %d", pass);
    
    [Spil closedParentalGate:pass];
}

// -- Game & Player data ---

// TODO: will be exposed later when the user profile is actually fully implemented
/*char* getUserProfileNative () {
    if([[SpilEventTracker sharedInstance] getDebug]) {
        NSLog(@"[HookBridge] getUserProfileNative");
    }
    
    NSString *jsonString = [Spil getUserProfile];
    return cStringCopy([jsonString UTF8String]);
}*/

void updatePlayerDataNative () {
    if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
        NSLog(@"[HookBridge] updatePlayerData");
    }
    
    [Spil updatePlayerData];
}

char* getWalletNative () {
    if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
        NSLog(@"[HookBridge] getWalletNative");
    }
    
    NSString *jsonString = [Spil getWallet];
    return cStringCopy([jsonString UTF8String]);
}

char* getSpilGameDataNative () {
    if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
        NSLog(@"[HookBridge] getSpilGameDataNative");
    }
    
    NSString *jsonString = [Spil getSpilGameData];
    return cStringCopy([jsonString UTF8String]);
}

char* getInventoryNative () {
    if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
        NSLog(@"[HookBridge] getInventoryNative");
    }
    
    NSString *jsonString = [Spil getInventory];
    return cStringCopy([jsonString UTF8String]);
}

void addCurrencyToWalletNative(int currencyId, int amount, char* reasonName) {
    if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
        NSLog(@"[HookBridge] addCurrencyToWallet");
    }
    
    NSString *reason = [NSString stringWithCString:reasonName encoding:NSUTF8StringEncoding];
    [Spil addCurrencyToWallet:currencyId withAmount:amount withReason:reason];
}

void subtractCurrencyFromWalletNative(int currencyId, int amount, char* reasonName) {
    if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
        NSLog(@"[HookBridge] subtractCurrencyFromWallet");
    }
    
    NSString *reason = [NSString stringWithCString:reasonName encoding:NSUTF8StringEncoding];
    [Spil subtractCurrencyFromWallet:currencyId withAmount:amount withReason:reason];
}

void addItemToInventoryNative(int itemId, int amount, char* reasonName) {
    if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
        NSLog(@"[HookBridge] addItemToInventory");
    }
    
    NSString *reason = [NSString stringWithCString:reasonName encoding:NSUTF8StringEncoding];
    [Spil addItemToInventory:itemId withAmount:amount withReason:reason];
}

void subtractItemFromInventoryNative(int itemId, int amount, char* reasonName) {
    if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
        NSLog(@"[HookBridge] subtractItemToInventory");
    }
    
    NSString *reason = [NSString stringWithCString:reasonName encoding:NSUTF8StringEncoding];
    [Spil subtractItemFromInventory:itemId withAmount:amount withReason:reason];
}

void consumeBundleNative(int itemId, char* reasonName) {
    if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
        NSLog(@"[HookBridge] consumeBundle");
    }
    
    NSString *reason = [NSString stringWithCString:reasonName encoding:NSUTF8StringEncoding];
    [Spil consumeBundle:itemId withReason:reason];
}

// --- Customer support ---

void showHelpCenterNative() {

}

void showContactCenterNative() {

}

void showHelpCenterWebviewNative() {

}

// --- Web ---

void requestDailyBonusNative() {
    if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
        NSLog(@"[HookBridge] requestDailyBonus");
    }
    
    [Spil requestDailyBonus];
}

void requestSplashScreenNative() {
    if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
        NSLog(@"[HookBridge] requestSplashScreen");
    }
    
    [Spil requestSplashScreen];
}

// --- User data ---

char* getUserIdNative() {
    NSLog(@"[HookBridge] getUserIdNative");
    
    NSString *uid = [Spil getUserId];
    if (uid == nil) {
        uid = @"";
    }
    
    NSLog(@"[HookBridge] getUserIdNative OUT: %@", uid);
    return cStringCopy([uid UTF8String]);
}

char* getUserProviderNative() {
    NSLog(@"[HookBridge] getUserProviderNative");
    
    NSString *provider = [Spil getUserProvider];
    if (provider == nil) {
        provider = @"";
    }
    
    NSLog(@"[HookBridge] getUserProviderNative OUT: %@", provider);
    return cStringCopy([provider UTF8String]);
}

void setUserIdNative(const char* providerId, const char* userId) {
    NSString *uId = [NSString stringWithCString:userId encoding:NSUTF8StringEncoding];
    NSString *sId = [NSString stringWithCString:providerId encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] setUserIdNative IN providerId: %@, userId: %@", uId, sId);
    
    [Spil setUserId:uId forProviderId:sId];
}

void setPrivateGameStateNative(const char* privateData) {
    NSString *pd = [NSString stringWithCString:privateData encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] setPrivateGameStateNative IN privateData: %@", pd);
    
    [Spil setPrivateGameState:pd];
}

char* getPrivateGameStateNative() {
    if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
        NSLog(@"[HookBridge] getPrivateGameStateNative");
    }
    
    NSString *jsonString = [Spil getPrivateGameState];
    return cStringCopy([jsonString UTF8String]);
}

void setPublicGameStateNative(const char* publicData) {
    NSString *pd = [NSString stringWithCString:publicData encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] setPublicGameStateNative IN publicData: %@", pd);
    
    [Spil setPublicGameState:pd];
}

char* getPublicGameStateNative() {
    if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
        NSLog(@"[HookBridge] getPublicGameStateNative");
    }
    
    NSString *jsonString = [Spil getPublicGameState];
    return cStringCopy([jsonString UTF8String]);
}

void getOtherUsersGameStateNative(const char* provider, const char* userIdsJsonArray) {
    NSString *providerString = [NSString stringWithCString:provider encoding:NSUTF8StringEncoding];
    NSString *uidsString = [NSString stringWithCString:userIdsJsonArray encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] setPublicGameStateNative IN userIdsJsonArray: %@", uidsString);
    
    NSArray *userIds = [JsonUtil convertStringToObject:uidsString];
    [Spil getOtherUsersGameState:providerString userIds:userIds];
}

@end
