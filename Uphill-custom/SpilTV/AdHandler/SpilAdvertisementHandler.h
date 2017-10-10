//
//  SpilAdvertisementHandler.h
//  Spil
//
//  Created by Martijn van der Gun on 11/2/15.
//  Copyright © 2015 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AdProvider.h"

static NSString* const ADPROVIDER_APPLOVIN = @"applovin";

@interface SpilAdvertisementHandler : NSObject

+(SpilAdvertisementHandler*)sharedInstance;

-(AdProvider*)getAdProvider:(NSString*)identifier;
-(BOOL)isAdProviderInitialized:(NSString*)identifier;

-(void)checkRewardVideoAvailability:(NSString*)adProvider;
-(void)showRewardVideo;
-(void)showRewardVideo:(NSString*)adProviderId;

-(void)showInterstitial:(NSString*)adProviderId;

// Dev method, not all options are routed
-(void)requestAd:(NSString*)provider withAdType:(NSString*)adType withParentalGate:(BOOL)parentalGate;

@end
