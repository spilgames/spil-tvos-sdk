//
//  AppLovinAdProvider.m
//  Spil
//
//  Created by Frank Slofstra on 20/04/16.
//  Copyright © 2015 Spil Games. All rights reserved.
//

#import "AppLovinAdProvider.h"
#import "Spil.h"
#import "SpilConfigHandler.h"

@interface AppLovinAdProvider ()

@property(nonatomic) BOOL initialized;
@property(nonatomic) BOOL loadingInterstitial;
@property(nonatomic) BOOL loadingRewardVideo;
@property(nonatomic, retain) ALSdk *alSDK;
@property(nonatomic, retain) ALInterstitialAd *interstitialAd;
@property(nonatomic, retain) ALIncentivizedInterstitialAd *rewardAd;

@end

@implementation AppLovinAdProvider

@synthesize initialized;
@synthesize loadingInterstitial;
@synthesize loadingRewardVideo;
@synthesize alSDK;
@synthesize interstitialAd;
@synthesize rewardAd;

-(void)initialize:(NSDictionary*)options {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        //[ALSdk initializeSdk];
        
        id sdkConfig = [[SpilConfigHandler sharedInstance] getConfigValue:@"iosSdkConfig"];
        if (sdkConfig != nil && [sdkConfig isKindOfClass:[NSDictionary class]]) {
            NSString *key = [sdkConfig objectForKey:@"applovin"];
            
            if (key != nil) {
                ALSdkSettings *settings = [[ALSdkSettings alloc] init];
                settings.isVerboseLogging = true;
                settings.autoPreloadAdSizes = @"INTER";
                settings.autoPreloadAdTypes = @"REGULAR,INCENTIVIZED";
                self.alSDK = [ALSdk sharedWithKey:key settings:settings];
                self.interstitialAd = [[ALInterstitialAd alloc] initWithSdk:alSDK];
                self.interstitialAd.adDisplayDelegate = self;
                self.rewardAd = [[ALIncentivizedInterstitialAd alloc] initWithSdk:alSDK];
                self.rewardAd.adDisplayDelegate = self;
                
                NSLog(@"[SpilAdvertisementHandler] AppLovin instance started, SDK key: %@", key);
                
                self.loadingRewardVideo = false;
                self.loadingInterstitial = false;
                self.initialized = YES;
            } else {
                NSLog(@"[SpilAdvertisementHandler] AppLovin instance error, key is not set in config!");
            }
        } else {
            NSLog(@"[SpilAdvertisementHandler] AppLovin instance error, config not found!");
        }
    });
}

-(BOOL)isInitialized {
    return self.initialized;
}

-(void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad {
    // Unhandled
}

-(void) ad: (alnonnull ALAd *) ad wasClickedIn: (alnonnull UIView *) view {
    // Unhandled
}

-(void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
    if (loadingInterstitial) {
        NSDictionary *data = @{@"type": @"interstitial"};
        [self sendAdNotification:@"adNotAvailable" data:data];
    } else {
        NSDictionary *data = @{@"type": @"rewardVideo"};
        [self sendAdNotification:@"adNotAvailable" data:data];
    }
}

#pragma mark Interstitials

-(void)checkInterstitialAvailability {
    // For now just start the interstitial, there is no check method right now needed
    [self showInterstitial];
}

-(void)showInterstitial {
    self.loadingInterstitial = true;
    self.loadingRewardVideo = false;
    
    dispatch_async(dispatch_get_main_queue(), ^ {
        if([self.interstitialAd isReadyForDisplay]){
            NSDictionary *data = @{@"type":@"interstitial"};
            [self sendAdNotification:@"adAvailable" data:data];
            
            [self.interstitialAd show];
        }
        else{
            NSDictionary *data = @{@"type":@"interstitial"};
            [self sendAdNotification:@"adNotAvailable" data:data];
        }
    });
}

-(void) ad: (alnonnull ALAd *) ad wasDisplayedIn: (alnonnull UIView *) view {
    [Spil trackEvent:@"interstitialDidDisplay" withParameters:nil];
    [self sendAdNotification:@"adStart"];
}

-(void) ad: (alnonnull ALAd *) ad wasHiddenIn: (alnonnull UIView *) view {
    [Spil trackEvent:@"interstitialDidClose" withParameters:nil];
    
    NSDictionary *data = @{@"type":@"interstitial", @"reason":@"dismiss", @"network":@"applovin"};
    [self sendAdNotification:@"adFinished" data:data];
}

#pragma mark Rewarded videos

-(void)checkRewardVideoAvailability {
    self.loadingInterstitial = false;
    self.loadingRewardVideo = true;

    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.rewardAd preloadAndNotify:self];
    });
}

-(void)showRewardVideo {
    self.loadingInterstitial = false;
    self.loadingRewardVideo = true;
    
    if([self.rewardAd isReadyForDisplay]){
        NSDictionary *data = @{@"type":@"rewardVideo"};
        [self sendAdNotification:@"adAvailable" data:data];
        
        [self.rewardAd showAndNotify: self];
    }
    else{
        NSDictionary *data = @{@"type":@"rewardVideo"};
        [self sendAdNotification:@"adNotAvailable" data:data];
    }
}

-(void) rewardValidationRequestForAd: (ALAd*) ad didSucceedWithResponse: (NSDictionary*) response {
    // Process the deltaOfCoins in the way that makes most sense for your application...
    NSLog(@"[SpilAdvertisementHandler] App lovin received delta of coins: %@", response);
    
    NSString* currencyName = [response objectForKey: @"currency"];
    int amountGiven = [[response objectForKey: @"amount"] intValue];
    
    // Send message to unity
    NSDictionary *eventData = @{@"reward":[NSNumber numberWithInteger:amountGiven],
                                @"currencyName":[NSString stringWithFormat:@"%@",currencyName],
                                @"currencyId":@"0"};
    
    [Spil trackEvent:@"rewardedVideoDidClose" withParameters:nil];
    
    NSDictionary *data = @{@"type":@"rewardVideo", @"reason":@"close", @"network":@"applovin", @"reward":eventData};
    [self sendAdNotification:@"adFinished" data:data];
}

-(void) videoPlaybackBeganInAd: (ALAd*) ad {
    [Spil trackEvent:@"rewardedVideoDidDisplay" withParameters:nil];
    
    [self sendAdNotification:@"adStart"];
}

-(void) videoPlaybackEndedInAd: (ALAd*) ad atPlaybackPercent:(NSNumber*) percentPlayed fullyWatched: (BOOL) wasFullyWatched {
    // This is handled through the reward delegate
}

-(void) rewardValidationRequestForAd: (ALAd*) ad didExceedQuotaWithResponse: (NSDictionary*) response {
    NSDictionary *data = @{@"type":@"rewardVideo", @"reason":@"dismiss", @"network":@"applovin"};
    [self sendAdNotification:@"adFinished" data:data];
}

-(void) rewardValidationRequestForAd: (ALAd*) ad wasRejectedWithResponse: (NSDictionary*) response {
    NSDictionary *data = @{@"type":@"rewardVideo", @"reason":@"dismiss", @"network":@"applovin"};
    [self sendAdNotification:@"adFinished" data:data];
}

-(void) rewardValidationRequestForAd: (ALAd*) ad didFailWithError: (NSInteger) responseCode {
    NSDictionary *data = @{@"type":@"rewardVideo", @"reason":@"dismiss", @"network":@"applovin"};
    [self sendAdNotification:@"adFinished" data:data];
}

-(void) userDeclinedToViewAd: (ALAd*) ad {
    NSDictionary *data = @{@"type":@"rewardVideo", @"reason":@"dismiss", @"network":@"applovin"};
    [self sendAdNotification:@"adFinished" data:data];
}

@end
