//
//  PlayerItem.m
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "PlayerItem.h"
#import "ClassUtil.h"

@implementation PlayerItem

@synthesize amount;
@synthesize delta;

-(id)init {
    self = [super init];
    
    return self;
}

-(id)initWithItem:(Item*)item {
    self = [super init];
    
    [ClassUtil copyParent:item intoChild:self];
    self.amount = 0;
    self.delta = 0;
    
    return self;
}

+(BOOL)propertyIsOptional:(NSString*)propertyName {
    return YES;
}

@end