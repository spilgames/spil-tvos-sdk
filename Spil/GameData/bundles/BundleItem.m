//
//  BundleItem.m
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "BundleItem.h"

@implementation BundleItem

@synthesize id;
@synthesize amount;

-(id)init {
    self = [super init];
    
    return self;
}

+(BOOL)propertyIsOptional:(NSString*)propertyName {
    return YES;
}

@end
