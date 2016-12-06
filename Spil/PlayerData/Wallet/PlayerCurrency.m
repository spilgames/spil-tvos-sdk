//
//  PlayerCurrency.m
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "PlayerCurrency.h"
#import "ClassUtil.h"

@implementation PlayerCurrency

@synthesize currentBalance;
@synthesize delta;

-(id)init {
    self = [super init];
    
    return self;
}

-(id)initWithCurrency:(Currency*)currency {
    self = [super init];
    
    [ClassUtil copyParent:currency intoChild:self];
    self.currentBalance = 0;
    self.delta = 0;
    
    return self;
}

+(BOOL)propertyIsOptional:(NSString*)propertyName {
    return YES;
}

@end