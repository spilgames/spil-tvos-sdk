//
//  BundlePrice.m
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "BundlePrice.h"

@implementation BundlePrice

@synthesize currencyId;
@synthesize value;

-(id)init {
    self = [super init];
    
    return self;
}

+(BOOL)propertyIsOptional:(NSString*)propertyName {
    return YES;
}

@end
