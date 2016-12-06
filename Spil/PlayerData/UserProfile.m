//
//  UserProfile.m
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "UserProfile.h"

@implementation UserProfile

@synthesize userID;
@synthesize facebookID;
@synthesize playGamesID;
@synthesize username;
@synthesize gender;
@synthesize country;

@synthesize wallet;
@synthesize inventory;

-(id)init {
    self = [super init];
    
    return self;
}

+(BOOL)propertyIsOptional:(NSString*)propertyName {
    return YES;
}

@end