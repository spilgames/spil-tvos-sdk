//
//  SpilAnalyticsHandler.m
//  Spil
//
//  Created by Frank Slofstra on 13/07/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SpilAnalyticsHandler.h"
#import <AdSupport/AdSupport.h>

@interface SpilAnalyticsHandler ()

@property(nonatomic, strong) NSMutableDictionary *analyticsProviders;

@end

@implementation SpilAnalyticsHandler

@synthesize analyticsProviders = _analyticsProviders;

+ (SpilAnalyticsHandler*)sharedInstance {
    static SpilAnalyticsHandler *instance = nil;
    if (instance == nil) {
        static dispatch_once_t p;
        dispatch_once(&p, ^{
            instance = [[SpilAnalyticsHandler alloc] init];
        });
    }
    return instance;
}

-(id)init {
    if (self = [super init] ) {
        self.analyticsProviders = [NSMutableDictionary dictionary];
    }
    return self;
}

-(void)initializeAnalyticsProviders {

}

-(BOOL)isUsingAdjust {
    return false;
}

-(NSString*)getIDFV {
    return [UIDevice.currentDevice identifierForVendor].UUIDString;
}

-(NSString*)getIDFA {
    if ([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]) {
        return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    } else {
        return nil;
    }
}

@end
