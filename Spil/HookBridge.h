//
//  HookBridge.h
//  SpilStaticLib
//
//  Created by Martijn van der Gun on 6/22/15.
//  Copyright (c) 2015 Martijn van der Gun. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface HookBridge : NSObject {
    
}

#ifdef __cplusplus
extern "C" {

    // --- Event tracking ---
    
    void initEventTracker();
    
    void initEventTrackerWithOptions(const char* options);
    
    void trackEventNative(const char* eventName);
    
    void trackEventWithParamsNative(const char* eventName, const char* jsonStringParams);
    
    // --- Default events (Not used by the unity plugin, it uses the generic track event methods ---
    
    void trackMilestoneAchievedEvent(const char* name);
    
    void trackLevelStartEvent(const char* level, int score, int stars, int turns, bool customCreated, const char* creatorId);
    
    void trackLevelCompleteEvent(const char* level, int score, int stars, int turns, bool customCreated, const char* creatorId);
    
    void trackLevelFailed(const char* level, int score, int stars, int turns, bool customCreated, const char* creatorId);

    void trackLevelUpEvent(const char* level, const char* objectId, const char* skillId);

    void trackEquipEvent(const char* equippedItem, const char* equippedTo);
    
    void trackUpgradeEvent(const char* upgradeId, const char* level, const char* reason, int iteration);
    
    void trackLevelCreateEvent(const char* levelId, const char* creatorId);
    
    void trackLevelDownloadEvent(const char* levelId, const char* creatorId, int rating);
    
    void trackLevelRateEvent(const char* levelId, const char* creatorId, int rating);

    void trackEndlessModeStartEvent();
    
    void trackEndlessModeEndEvent(int distance);

    void trackPlayerDiesEvent(const char* level);
    
    void trackWalletInventoryEvent(const char* currencyList, const char* itemsList, const char* reason, const char* location);
    
    void trackIAPPurchasedEvent(const char* skuId, const char* transactionId, const char* purchaseDate);

    void trackIAPRestoredEvent(const char* skuId, const char* originalTransactionId, const char* originalPurchaseDate);

    void trackIAPFailedEvent(const char* skuId, const char* error);

    void trackTutorialCompleteEvent();
    
    void trackTutorialSkippedEvent();
    
    void trackRegisterEvent(const char* platform);

    void trackShareEvent(const char* platform);

    void trackInviteEvent(const char* platform);
    
    // --- Push messages ---
    
    void disableAutomaticRegisterForPushNotificationsNative();
    
    void registerForPushNotifications();
    
    void setPushNotificationKey(const char* pushKey);
    
    void handlePushNotification(const char* notificationStringParams);
    
    // --- App flow ---
    
    void applicationDidFinishLaunchingWithOptions(const char* launchOptions);
    
    void applicationDidEnterBackground();
    
    void applicationDidBecomeActive();
    
    // --- Util ---
    
    void setCustomBundleIdNative(const char* bundleId);
    
    void UnitySendMessage(const char* obj, const char* method, const char* msg);
    
    char* cStringCopy(const char* string);
    
    char* getSpilUserIdNative();
    
    void setPluginInformationNative(const char* pluginName, const char* pluginVersion);

    // --- Config ---
    
    char* getConfigNative();
    
    char* getConfigValueNative(const char* keyName);
    
    // --- Packages & Promotions ---
    
    void requestPackagesNative();
    
    char* getPackageNative(const char* keyName);
    
    char* getAllPackagesNative();
    
    char* getPromotionNative(const char* keyName);

    // --- ADS ---
    
    void showMoreAppsNative();
    
    void requestRewardVideoNative(const char* rewardType);

    void playRewardVideoNative();
    
    void devRequestAdNative(const char* providerName, const char* adTypeName, const bool parentalGate);
    
    void devShowRewardVideoNative(const char* providerName);
    
    void devShowInterstitialNative(const char* providerName);
    
    void devShowMoreAppsNative(const char* providerName);

    void showToastOnVideoReward(const bool enabled);
    
    void closedParentalGateNative(const bool pass);
    
    // --- Game & Player data ---
    
    void updatePlayerDataNative();

    char* getWalletNative();
    
    char* getSpilGameDataNative();
    
    char* getInventoryNative();
    
    void addCurrencyToWalletNative(int currencyId, int amount, char* reasonName, char* location);
    
    void subtractCurrencyFromWalletNative(int currencyId, int amount, char* reasonName, char* location);
    
    void addItemToInventoryNative(int itemId, int amount, char* reasonName, char* location);
    
    void subtractItemFromInventoryNative(int itemId, int amount, char* reasonName, char* location);
    
    void buyBundleNative(int itemId, char* reasonName, char* location);
    
    void resetPlayerDataNative();
    
    void resetInventoryNative();
    
    void resetWalletNative();
    
    // --- Customer support ---
    
    void showHelpCenterNative();
    
    void showContactCenterNative();
    
    void showHelpCenterWebviewNative();
    
    // --- Web ---
    
    void requestDailyBonusNative();
    
    void requestSplashScreenNative();
    
    // --- User data ---
    
    char* getUserIdNative();
    
    char* getUserProviderNative();
    
    void setUserIdNative(const char* providerId, const char* userId);

    void setPrivateGameStateNative(const char* privateData);

    char* getPrivateGameStateNative();

    void setPublicGameStateNative(const char* publicData);
    
    char* getPublicGameStateNative();

    void getOtherUsersGameStateNative(const char* provider, const char* userIdsJsonArray);
}

#endif

+ (void)sendMessage:(NSString*)messageName toObject:(NSString*)objectName withParameter:(NSString*)parameterString;

@end
