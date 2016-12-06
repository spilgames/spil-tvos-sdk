//
//  ShopPromotion.m
//  Spil
//
//  Created by Frank Slofstra on 14/06/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "ShopPromotion.h"

@implementation ShopPromotion

@synthesize bundleId;
@synthesize amount;
@synthesize prices;
@synthesize discount;
@synthesize startDate;
@synthesize endDate;

-(id)init {
    self = [super init];
    
    return self;
}

+(BOOL)propertyIsOptional:(NSString*)propertyName {
    return YES;
}

@end