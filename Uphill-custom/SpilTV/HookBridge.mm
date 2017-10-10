//
//  HookBridge.cpp
//  SpilStaticLib
//
//  Copyright (c) 2015 Spil Games. All rights reserved.
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
            UnitySendMessage([objectName cStringUsingEncoding:NSUTF8StringEncoding],
                             [messageName cStringUsingEncoding:NSUTF8StringEncoding],
                             [parameterString cStringUsingEncoding:NSUTF8StringEncoding]);
    }
}

/*+ (NSString*) getLocalSecret {
    return [NSString stringWithCString:getLocalSecretEx() encoding:NSUTF8StringEncoding];
}*/

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

void requestServerTimeNative() {
    NSLog(@"[HookBridge] requestServerTime");
    
    //[Spil requestServerTime];
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

// --- Default events (Not used by the unity plugin, it uses the generic track event methods ---

void trackMilestoneAchievedEvent(const char* name) {
    NSString *n = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackMilestoneAchievedEvent IN name: %@", n);
    [Spil trackMilestoneAchievedEvent:n];
}

void trackLevelStartEvent(const char* level, bool customCreated, const char* creatorId) {
    NSString *l = [NSString stringWithCString:level encoding:NSUTF8StringEncoding];
    NSString *ci = [NSString stringWithCString:creatorId encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackLevelStartEvent IN level: %@, customCreated: %d, creatorId: %@", l, customCreated, ci);
    [Spil trackLevelStartEvent:l score:0 stars:0 turns:0 customCreated:customCreated creatorId:ci];
}

void trackLevelCompleteEvent(const char* level, int score, int stars, int turns, bool customCreated, const char* creatorId) {
    NSString *l = [NSString stringWithCString:level encoding:NSUTF8StringEncoding];
    NSString *ci = [NSString stringWithCString:creatorId encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackLevelCompleteEvent IN level: %@, score: %d, stars: %d, turns: %d, customCreated: %d, creatorId: %@", l, score, stars, turns, customCreated, ci);
    [Spil trackLevelCompleteEvent:l score:score stars:stars turns:turns customCreated:customCreated creatorId:ci];
}

void trackLevelFailed(const char* level, int score, int stars, int turns, bool customCreated, const char* creatorId) {
    NSString *l = [NSString stringWithCString:level encoding:NSUTF8StringEncoding];
    NSString *ci = [NSString stringWithCString:creatorId encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackLevelFailed IN level: %@, score: %d, stars: %d, turns: %d, customCreated: %@, creatorId: %@", l, score, stars, turns, (customCreated ? @"YES" : @"NO"), ci);
    [Spil trackLevelFailedEvent:l score:score stars:stars turns:turns customCreated:customCreated creatorId:ci];
}

void trackLevelUpEvent(const char* level, const char* objectId, const char* skillId) {
    NSString *l = [NSString stringWithCString:level encoding:NSUTF8StringEncoding];
    NSString *o = [NSString stringWithCString:objectId encoding:NSUTF8StringEncoding];
    NSString *s = [NSString stringWithCString:skillId encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackLevelUpEvent IN level: %@, objectId: %@, skillId: %@", l, o, s);
    [Spil trackLevelUpEvent:l objectId:o skillId:s];
}

void trackEquipEvent(const char* equippedItem, const char* equippedTo) {
    NSString *i = [NSString stringWithCString:equippedItem encoding:NSUTF8StringEncoding];
    NSString *t = [NSString stringWithCString:equippedTo encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackEquipEvent IN equippedItem: %@, equippedTo: %@", i, t);
    [Spil trackEquipEvent:i equippedTo:t];
}

void trackUpgradeEvent(const char* upgradeId, const char* level, const char* reason, int iteration) {
    NSString *u = [NSString stringWithCString:upgradeId encoding:NSUTF8StringEncoding];
    NSString *l = [NSString stringWithCString:level encoding:NSUTF8StringEncoding];
    NSString *r = [NSString stringWithCString:reason encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackUpgradeEvent IN upgradeId: %@, level: %@, reason: %@, iteration: %d", u, l, r, iteration);
    [Spil trackUpgradeEvent:u level:l reason:r iteration:iteration];
}

void trackLevelCreateEvent(const char* levelId, const char* creatorId) {
    NSString *l = [NSString stringWithCString:levelId encoding:NSUTF8StringEncoding];
    NSString *c = [NSString stringWithCString:creatorId encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackLevelCreateEvent IN levelId: %@, creatorId: %@", l, c);
    [Spil trackLevelCreateEvent:l creatorId:c];
}

void trackLevelDownloadEvent(const char* levelId, const char* creatorId, int rating) {
    NSString *l = [NSString stringWithCString:levelId encoding:NSUTF8StringEncoding];
    NSString *c = [NSString stringWithCString:creatorId encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackLevelDownloadEvent IN levelId: %@, creatorId: %@, rating: %d", l, c, rating);
    [Spil trackLevelDownloadEvent:l creatorId:c rating:rating];
}

void trackLevelRateEvent(const char* levelId, const char* creatorId, int rating) {
    NSString *l = [NSString stringWithCString:levelId encoding:NSUTF8StringEncoding];
    NSString *c = [NSString stringWithCString:creatorId encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackLevelRateEvent IN levelId: %@, creatorId: %@, rating: %d", l, c, rating);
    [Spil trackLevelRateEvent:l creatorId:c rating:rating];
}

void trackEndlessModeStartEvent() {
    NSLog(@"[HookBridge] trackEndlessModeStartEvent");
    [Spil trackEndlessModeStartEvent];
}

void trackEndlessModeEndEvent(int distance) {
    NSLog(@"[HookBridge] trackEndlessModeEndEvent IN distance: %d", distance);
    [Spil trackEndlessModeEndEvent:distance];
}

void trackPlayerDiesEvent(const char* level) {
    NSString *l = [NSString stringWithCString:level encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackPlayerDiesEvent IN level: %@", l);
    [Spil trackPlayerDiesEvent:l];
}

void trackWalletInventoryEvent(const char* currencyList, const char* itemsList, const char* reason, char* reasonDetails, const char* location) {
    NSString *currency = [NSString stringWithCString:currencyList encoding:NSUTF8StringEncoding];
    NSString *items = [NSString stringWithCString:itemsList encoding:NSUTF8StringEncoding];
    NSString *r = [NSString stringWithCString:reason encoding:NSUTF8StringEncoding];
    //NSString *details = [NSString stringWithCString:reasonDetails encoding:NSUTF8StringEncoding];
    NSString *l = [NSString stringWithCString:location encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] trackWalletInventoryEvent IN itemsList: %@, itemsList: %@, reason: %@, location: %@", currency, items, r, l);
    [Spil trackWalletInventoryEvent:r location:l currencyList:currency itemList:items];
}

void trackIAPPurchasedEvent(const char* skuId, const char* transactionId, const char* purchaseDate) {
    NSString *sku = [NSString stringWithCString:skuId encoding:NSUTF8StringEncoding];
    NSString *transaction = [NSString stringWithCString:transactionId encoding:NSUTF8StringEncoding];
    NSString *purchase = [NSString stringWithCString:purchaseDate encoding:NSUTF8StringEncoding];
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

// Not used
/*void applicationDidFinishLaunchingWithOptions(const char* launchOptions) {
 NSString *launchOptionsString = [NSString stringWithCString:launchOptions encoding:NSUTF8StringEncoding];
 NSLog(@"[HookBridge] applicationDidFinishLaunchingWithOptions: %@", launchOptionsString);
 
 NSData *data = [launchOptionsString dataUsingEncoding:NSUTF8StringEncoding];
 NSDictionary *params = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
 
 [Spil application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:params];
 }*/

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
    NSLog(@"[HookBridge] registerForPushNotificationsNative");
    
    [Spil disableAutomaticRegisterForPushNotifications];
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

// --- Token claiming ---

void claimTokenNative(const char* token, const char* rewardType) {
    NSString *tokenParam = [NSString stringWithCString:token encoding:NSUTF8StringEncoding];
    NSString *rewardParam = [NSString stringWithCString:rewardType encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] claimTokenNative IN token: %@ rewardType: %@", tokenParam, rewardParam);
    //[Spil claimToken:tokenParam withRewardType:rewardParam];
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
    NSLog(@"[HookBridge] getAllPackagesNative");
    
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
    
    NSLog(@"[HookBridge] getAllPackagesNative OUT: %@", json_string);
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

char* getPromotionsNative (const char* keyName) {
    NSString *key = [NSString stringWithCString:keyName encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] getPromotionsNative IN %@", key);
    
    NSString* json_string = @"[]";
    
    NSLog(@"[HookBridge] getPromotionsNative OUT %@", json_string);
    char* s = cStringCopy([json_string UTF8String]);
    return s;
}

// -- ADS ---

void requestMoreAppsNative () {
    NSLog(@"[HookBridge] requestMoreAppsNative");
    
    //[Spil requestMoreApps];
}

void showMoreAppsNative () {
    NSLog(@"[HookBridge] showMoreAppsNative");
    
    [Spil showMoreApps];
}

void requestRewardVideoNative(const char* rewardType) {
    NSString *r = [NSString stringWithCString:rewardType encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] requestRewardVideoNative IN name: %@", r);
    [Spil requestRewardVideo:r];
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

void updatePlayerDataNative () {
    NSLog(@"[HookBridge] updatePlayerData");
    
    [Spil updatePlayerData];
}

char* getWalletNative () {
    NSLog(@"[HookBridge] getWalletNative");
    
    NSString *jsonString = [Spil getWallet];
    
    NSLog(@"[HookBridge] getWalletNative OUT: %@", jsonString);
    return cStringCopy([jsonString UTF8String]);
}

char* getSpilGameDataNative () {
    NSLog(@"[HookBridge] getSpilGameDataNative");
    
    NSString *jsonString = [Spil getSpilGameData];
    NSLog(@"[HookBridge] getSpilGameDataNative OUT: %@", jsonString);
    return cStringCopy([jsonString UTF8String]);
}

char* getInventoryNative () {
    NSLog(@"[HookBridge] getInventoryNative");
    
    NSString *jsonString = [Spil getInventory];
    NSLog(@"[HookBridge] getInventoryNative OUT: %@", jsonString);
    return cStringCopy([jsonString UTF8String]);
}

void addCurrencyToWalletNative(int currencyId, int amount, char* reasonName, char* locationName, char* reasonDetails, char* transactionId) {
    NSLog(@"[HookBridge] addCurrencyToWallet");
    
    NSString *reason = [NSString stringWithCString:reasonName encoding:NSUTF8StringEncoding];
    NSString *details = reasonDetails == nil ? nil : [NSString stringWithCString:reasonDetails encoding:NSUTF8StringEncoding];
    NSString *location = [NSString stringWithCString:locationName encoding:NSUTF8StringEncoding];
    NSString *transaction = transactionId == nil ? nil : [NSString stringWithCString:transactionId encoding:NSUTF8StringEncoding];
    
    NSLog(@"[HookBridge] addCurrencyToWallet IN %d, %d, %@, %@, %@, %@", currencyId, amount, reason, details, location, transaction);
    //[Spil addCurrencyToWallet:currencyId withAmount:amount withReason:reason withReasonDetails:details withLocation:location withTransactionId:transaction];
}

void subtractCurrencyFromWalletNative(int currencyId, int amount, char* reasonName, char* locationName, char* reasonDetails, char* transactionId) {
    NSLog(@"[HookBridge] subtractCurrencyFromWallet");
    
    /*NSString *reason = [NSString stringWithCString:reasonName encoding:NSUTF8StringEncoding];
    NSString *details = reasonDetails == nil ? nil : [NSString stringWithCString:reasonDetails encoding:NSUTF8StringEncoding];
    NSString *location = [NSString stringWithCString:locationName encoding:NSUTF8StringEncoding];
    NSString *transaction = transactionId == nil ? nil : [NSString stringWithCString:transactionId encoding:NSUTF8StringEncoding];*/
    //[Spil subtractCurrencyFromWallet:currencyId withAmount:amount withReason:reason withReasonDetails:details withLocation:location withTransactionId:transaction];
}

void addItemToInventoryNative(int itemId, int amount, char* reasonName, char* locationName, char* reasonDetails, char* transactionId) {
    NSLog(@"[HookBridge] addItemToInventory");
    
    /*NSString *reason = [NSString stringWithCString:reasonName encoding:NSUTF8StringEncoding];
    NSString *details = reasonDetails == nil ? nil : [NSString stringWithCString:reasonDetails encoding:NSUTF8StringEncoding];
    NSString *location = [NSString stringWithCString:locationName encoding:NSUTF8StringEncoding];
    NSString *transaction = transactionId == nil ? nil : [NSString stringWithCString:transactionId encoding:NSUTF8StringEncoding];*/
    //[Spil addItemToInventory:itemId withAmount:amount withReason:reason withReasonDetails:details withLocation:location withTransactionId:transaction];
}

void subtractItemFromInventoryNative(int itemId, int amount, char* reasonName, char* locationName, char* reasonDetails, char* transactionId) {
    NSLog(@"[HookBridge] subtractItemToInventory");
    
    /*NSString *reason = [NSString stringWithCString:reasonName encoding:NSUTF8StringEncoding];
    NSString *details = reasonDetails == nil ? nil : [NSString stringWithCString:reasonDetails encoding:NSUTF8StringEncoding];
    NSString *location = [NSString stringWithCString:locationName encoding:NSUTF8StringEncoding];
    NSString *transaction = transactionId == nil ? nil : [NSString stringWithCString:transactionId encoding:NSUTF8StringEncoding];*/
    //[Spil subtractItemFromInventory:itemId withAmount:amount withReason:reason withReasonDetails:details withLocation:location withTransactionId:transaction];
}

void buyBundleNative(int itemId, char* reasonName, char* locationName, char* reasonDetails, char* transactionId) {
    NSLog(@"[HookBridge] buyBundleNative");
    
    /*NSString *reason = [NSString stringWithCString:reasonName encoding:NSUTF8StringEncoding];
    NSString *details = reasonDetails == nil ? nil : [NSString stringWithCString:reasonDetails encoding:NSUTF8StringEncoding];
    NSString *location = [NSString stringWithCString:locationName encoding:NSUTF8StringEncoding];
    NSString *transaction = transactionId == nil ? nil : [NSString stringWithCString:transactionId encoding:NSUTF8StringEncoding];
    [Spil buyBundle:itemId withReason:reason withReasonDetails:details withLocation:location withTransactionId:transaction];*/
}

void openGachaNative(int itemId, char* reasonName, char* reasonDetails, char* locationName) {
    NSString *reason = [NSString stringWithCString:reasonName encoding:NSUTF8StringEncoding];
    NSString *details = reasonDetails == nil ? nil : [NSString stringWithCString:reasonDetails encoding:NSUTF8StringEncoding];
    NSString *location = [NSString stringWithCString:locationName encoding:NSUTF8StringEncoding];
    
    NSLog(@"[HookBridge] openGachaNative IN itemId: %d, location: %@, reason: %@, details: %@", itemId, reason, details, location);
    //[Spil openGacha:itemId withReason:reason withReasonDetails:details withLocation:location];
}

void resetPlayerDataNative () {
    [Spil resetPlayerData];
}

void resetInventoryNative () {
    [Spil resetInventory];
}

void resetWalletNative () {
    [Spil resetWallet];
}

// --- Customer support ---

void showHelpCenterNative() {
    NSLog(@"[HookBridge] showHelpCenterNative");
    
    [Spil showHelpCenter];
}

void showContactCenterNative() {
    NSLog(@"[HookBridge] showContactCenterNative");
    
    [Spil showContactCenter];
}

void showHelpCenterWebviewNative(char* url) {
    NSString *inputUrl = [NSString stringWithCString:url encoding:NSUTF8StringEncoding];
    
    NSLog(@"[HookBridge] showHelpCenterWebviewNative url:%@", inputUrl);
    
    //[Spil showHelpCenterWebview:inputUrl];
}

// --- Web ---

void requestDailyBonusNative() {
    NSLog(@"[HookBridge] requestDailyBonus");
    
    [Spil requestDailyBonus];
}

void requestSplashScreenNative() {
    NSLog(@"[HookBridge] requestSplashScreen");
    
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
    NSLog(@"[HookBridge] getPrivateGameStateNative");
    
    NSString *jsonString = [Spil getPrivateGameState];
    NSLog(@"[HookBridge] getPrivateGameStateNative OUT: %@", jsonString);
    return cStringCopy([jsonString UTF8String]);
}

void setPublicGameStateNative(const char* publicData) {
    NSString *pd = [NSString stringWithCString:publicData encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] setPublicGameStateNative IN publicData: %@", pd);
    
    [Spil setPublicGameState:pd];
}

char* getPublicGameStateNative() {
    NSLog(@"[HookBridge] getPublicGameStateNative");
    
    NSString *jsonString = [Spil getPublicGameState];
    NSLog(@"[HookBridge] getPublicGameStateNative OUT: %@", jsonString);
    return cStringCopy([jsonString UTF8String]);
}

void getOtherUsersGameStateNative(const char* provider, const char* userIdsJsonArray) {
    NSString *providerString = [NSString stringWithCString:provider encoding:NSUTF8StringEncoding];
    NSString *uidsString = [NSString stringWithCString:userIdsJsonArray encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] getOtherUsersGameStateNative IN userIdsJsonArray: %@", uidsString);
    
    NSArray *userIds = [JsonUtil convertStringToObject:uidsString];
    [Spil getOtherUsersGameState:providerString userIds:userIds];
}

void requestMyGameStateNative() {
    NSLog(@"[HookBridge] requestMyGameStateNative");
    
    //[Spil requestMyGameState];
}

// --- Image cache ---

char* getImagePathNative(char* url) {
    NSString *u = [NSString stringWithCString:url encoding:NSUTF8StringEncoding];
    
    NSString *path = @"";
    NSLog(@"[HookBridge] getImagePathNative IN url: %@, OUT path: %@", u, path);
    
    return cStringCopy([path UTF8String]);
}

void requestImageNative(char* url, int idx, char* imageType) {
    NSString *u = [NSString stringWithCString:url encoding:NSUTF8StringEncoding];
    NSString *i = [NSString stringWithCString:imageType encoding:NSUTF8StringEncoding];
    NSLog(@"[HookBridge] requestImageNative IN url: %@ id: %d, imageType: %@", u, idx, i);
    
    //[Spil requestImage:u withId:idx withImageType:i];
}

void clearDiskCacheNative() {
    NSLog(@"[HookBridge] clearDiskCacheNative");
    
    //[Spil clearDiskCache];
}

void preloadItemAndBundleImagesNative() {
    NSLog(@"[HookBridge] preloadItemAndBundleImagesNative");
    
    //[Spil preloadItemAndBundleImages];
}

// --- Live events ---

void requestLiveEventNative() {
    NSLog(@"[HookBridge] requestLiveEventNative");
    
    //[Spil requestLiveEvent];
}

void openLiveEventNative() {
    NSLog(@"[HookBridge] openLiveEventNative");
    
    //[Spil openLiveEvent];
}

char* getLiveEventStartDateNative() {
    NSString *o = @"";//[NSString stringWithFormat:@"%d", [Spil getLiveEventStartDate]];
    NSLog(@"[HookBridge] getLiveEventStartTimeNative OUT: %@", o);
    return cStringCopy([o UTF8String]);
}

char* getLiveEventEndDateNative() {
    NSString *o = @"";//[NSString stringWithFormat:@"%d", [Spil getLiveEventStartDate]];
    NSLog(@"[HookBridge] getLiveEventEndTimeNative OUT: %@", o);
    return cStringCopy([o UTF8String]);
}

char* getLiveEventConfigNative() {
    NSString *o = @"";//[JsonUtil convertObjectToJson:[Spil getLiveEventConfig]];
    NSLog(@"[HookBridge] getLiveEventConfigNative OUT: %@", o);
    return cStringCopy([o UTF8String]);
}

@end
