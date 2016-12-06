//
//  AdProvider.h
//  Spil
//
//  Created by Frank Slofstra on 20/04/16.
//  Copyright © 2015 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AdProvider : NSObject 

-(void)initialize:(NSDictionary*)options;
-(BOOL)isInitialized;

-(void)checkInterstitialAvailability;
-(void)showInterstitial;

-(void)checkRewardVideoAvailability;
-(void)showRewardVideo;

-(void)showMoreApps;

-(void)sendAdNotification:(NSString*)message;
-(void)sendAdNotification:(NSString*)message data:(NSDictionary*)data;

@end