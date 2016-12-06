//
//  AdProvider.m
//  Spil
//
//  Created by Frank Slofstra on 20/04/16.
//  Copyright © 2015 Spil Games. All rights reserved.
//

#import "AdProvider.h"
#import "Spil.h"

@interface AdProvider ()

@end

@implementation AdProvider

-(void)initialize:(NSDictionary*)options { }

-(BOOL)isInitialized { return NO; }

-(void)showInterstitial { }

-(void)showRewardVideo { }

-(void)showMoreApps { }

-(void)sendAdNotification:(NSString*)message {
    [self sendAdNotification:message data:nil];
}

-(void)sendAdNotification:(NSString*)message data:(NSDictionary*)data {
    NSDictionary *userInfo = nil;
    if (data != nil) {
        userInfo = @{@"event":message, @"data":data};
    } else {
        userInfo = @{@"event":message};
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
    
    [self sendUnityMessage:message data:data];
}

// Helper method
-(void)sendUnityMessage:(NSString*)message data:(NSDictionary*)data {
    @try {
        if ([message isEqualToString:@"adAvailable"]) {
            [Spil sendMessage:@"AdAvailable" toObject:@"SpilSDK" withString:data[@"type"]];
        } else if ([message isEqualToString:@"adNotAvailable"]) {
            [Spil sendMessage:@"AdNotAvailable" toObject:@"SpilSDK" withString:data[@"type"]];
        } else if ([message isEqualToString:@"adStart"]) {
            [Spil sendMessage:@"AdStart" toObject:@"SpilSDK" withString:@""];
        } else if ([message isEqualToString:@"adFinished"]) {
            NSString *jsonDataString = [JsonUtil convertObjectToJson:data];
            [Spil sendMessage:@"AdFinished" toObject:@"SpilSDK" withString:jsonDataString];
        } else if ([message isEqualToString:@"openParentalGate"]) {
            [Spil sendMessage:@"OpenParentalGate" toObject:@"SpilSDK" withString:@""];
        }
    }@catch (NSException *exception) {
        NSLog(@"[SpilAdvertisementHandler] Ad exception:%@",exception);
    }@finally {
        
    }
}

-(void)checkRewardVideoAvailability {
    
}

-(void)checkInterstitialAvailability {
    
}

@end
