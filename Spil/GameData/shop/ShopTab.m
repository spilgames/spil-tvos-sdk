//
//  ShopTab.m
//  Spil
//
//  Created by Frank Slofstra on 14/06/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "ShopTab.h"

@implementation ShopTab

@synthesize position;
@synthesize name;
@synthesize entries;

-(id)init {
    self = [super init];
    
    return self;
}

+(BOOL)propertyIsOptional:(NSString*)propertyName {
    return YES;
}

@end