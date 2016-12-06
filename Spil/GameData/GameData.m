//
//  GameData.m
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "GameData.h"

@implementation GameData

@synthesize items;
@synthesize currencies;
@synthesize bundles;
@synthesize shop;
@synthesize promotions;

-(id)init {
    self = [super init];
    
    return self;
}

+(BOOL)propertyIsOptional:(NSString*)propertyName {
    return YES;
}

@end