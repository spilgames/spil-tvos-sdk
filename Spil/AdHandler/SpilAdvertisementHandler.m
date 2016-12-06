//
//  SpilAdvertisementHandler.m
//  Spil
//
//  Created by Martijn van der Gun on 11/2/15.
//  Copyright © 2015 Spil Games. All rights reserved.
//

#import "SpilAdvertisementHandler.h"

@interface SpilAdvertisementHandler ()

@property(nonatomic, strong) NSMutableDictionary *adProviders;
@property(nonatomic, strong) NSString *rewardVideoAdProvider;
@property(nonatomic, strong) NSString *interstitialAdProvider;

@end

@implementation SpilAdvertisementHandler

@synthesize adProviders = _adProviders;

static SpilAdvertisementHandler* sharedInstance;

+ (SpilAdvertisementHandler*)sharedInstance {
    static SpilAdvertisementHandler *spilAdvertisementHandler = nil;
    if (spilAdvertisementHandler == nil) {
        static dispatch_once_t p;
        dispatch_once(&p, ^{
            spilAdvertisementHandler = [[SpilAdvertisementHandler alloc] init];
        });
    }
    return spilAdvertisementHandler;
}

-(id)init {
    if (self = [super init] ) {
        self.adProviders = [NSMutableDictionary dictionary];
        
        [self.adProviders setValue:[[AppLovinAdProvider alloc] init] forKey:ADPROVIDER_APPLOVIN];
    }
    return self;
}

-(AdProvider*)getAdProvider:(NSString*)identifier {
    NSString *adProviderLower = [identifier lowercaseString];
    return [self.adProviders objectForKey:adProviderLower];
}

-(AppLovinAdProvider*)getAppLovinAdProvider {
    return (AppLovinAdProvider*)[self getAdProvider:ADPROVIDER_APPLOVIN];
}

-(BOOL)isAdProviderInitialized:(NSString*)identifier {
    NSString *adProviderLower = [identifier lowercaseString];
    return [[self getAdProvider:adProviderLower] isInitialized];
}

-(void)requestAd:(NSString*)provider withAdType:(NSString*)adType withParentalGate:(BOOL)parentalGate {
    NSString *adProviderLower = [provider lowercaseString];
    if ([[adType lowercaseString] isEqualToString:@"rewardvideo"]) {
        [self checkRewardVideoAvailability:adProviderLower];
    } else if ([[adType lowercaseString] isEqualToString:@"interstitial"]) {
        [self checkInterstitialAvailability:adProviderLower];
    }
}

#pragma mark reward video

-(void)checkRewardVideoAvailability:(NSString*)adProvider {
    NSString *adProviderLower = [adProvider lowercaseString];
    AdProvider *provider = [self getAdProvider:adProviderLower];
    if (provider != nil) {
        self.rewardVideoAdProvider = adProviderLower;
        [provider checkRewardVideoAvailability];
    } else {
        NSLog(@"[SpilAdvertisementHandler] Error: Unknown ad provider: %@", adProviderLower);
    }
}

-(void)showRewardVideo {
    if (self.rewardVideoAdProvider == nil) {
        NSLog(@"[SpilAdvertisementHandler] Error: Ad provider not set, call [Spil trackEvent:@\"requestRewardVideo\"] first!");
    } else {
        AdProvider *adProvider = [self getAdProvider:self.rewardVideoAdProvider];
        [adProvider showRewardVideo];
        self.rewardVideoAdProvider = nil;
    }
}

-(void)showRewardVideo:(NSString*)adProviderId {
    AdProvider *adProvider = [self getAdProvider:adProviderId];
    [adProvider showRewardVideo];
}

#pragma mark interstitial

-(void)checkInterstitialAvailability:(NSString*)adProviderId {
    NSString *adProviderLower = [adProviderId lowercaseString];
    AdProvider *provider = [self getAdProvider:adProviderLower];
    if (provider != nil) {
        self.interstitialAdProvider = adProviderLower;
        [provider checkInterstitialAvailability];
    } else {
        NSLog(@"[SpilAdvertisementHandler] Error: Unknown ad provider: %@", adProviderLower);
    }
}

// TODO: Not needed yet, the request method automatically starts interstitials, always uses Fyber now
/*-(void)showInterstitial {
    if (self.interstitialAdProvider == nil) {
        NSLog(@"[SpilAdvertisementHandler] Error: Ad provider not set, call [Spil trackEvent:@\"requestInterstitial\"] first!");
    } else {
        AdProvider *adProvider = [self getFyberAdProvider];
        [adProvider showInterstitial];
    }
}*/

-(void)showInterstitial:(NSString*)adProviderId {
    NSString *adProviderLower = [adProviderId lowercaseString];
    AdProvider *provider = [self getAdProvider:adProviderLower];
    if (provider != nil) {
        [provider showInterstitial];
    } else {
        NSLog(@"[SpilAdvertisementHandler] Error: Unknown ad provider: %@", adProviderLower);
    }
}

@end
