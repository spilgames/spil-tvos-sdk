//
//  FyberAdProvider.h
//  Spil
//
//  Created by Frank Slofstra on 20/04/16.
//  Copyright © 2015 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AdProvider.h"
#import "ALSdk.h"
#import "ALAdRewardDelegate.h"
#import "ALInterstitialAd.h"
#import "ALIncentivizedInterstitialAd.h"

@interface AppLovinAdProvider : AdProvider<ALAdDisplayDelegate, ALAdVideoPlaybackDelegate, ALAdRewardDelegate, ALAdLoadDelegate>

@end
