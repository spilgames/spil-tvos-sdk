//
//  SpilAnalyticsHandler.h
//  Spil
//
//  Created by Frank Slofstra on 13/07/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString* const ANALYTICSPROVIDER_ADJUST = @"Adjust";
static NSString* const ANALYTICSPROVIDER_GOOGLE = @"Google";

@interface SpilAnalyticsHandler : NSObject

+(SpilAnalyticsHandler*)sharedInstance;

-(void)initializeAnalyticsProviders;

-(BOOL)isUsingAdjust;
-(NSString*)getIDFV;
-(NSString*)getIDFA;

@end