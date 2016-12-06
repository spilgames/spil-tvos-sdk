//
//  Bundle.m
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "Bundle.h"

@implementation Bundle

@synthesize id;
@synthesize name;
@synthesize prices;
@synthesize items;

-(id)init {
    self = [super init];
    
    return self;
}

+(BOOL)propertyIsOptional:(NSString*)propertyName {
    return YES;
}

@end
