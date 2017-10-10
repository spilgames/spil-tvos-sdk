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
    self.currentBalance = currency.initialValue;
    self.initialValue = currency.initialValue;
    self.delta = currency.initialValue;
    
    return self;
}

-(id)initWithDictionary:(NSDictionary*)dict {
    self = [super initWithDictionary:dict];
    
    self.currentBalance = [dict[@"currentBalance"] intValue];
    self.delta = [dict[@"delta"] intValue];
    
    return self;
}

-(NSDictionary*)toJSONObject {
    NSMutableDictionary *rootDict = [super toJSONObject];
    
    [rootDict setObject:[NSNumber numberWithInt:self.currentBalance] forKey:@"currentBalance"];
    [rootDict setObject:[NSNumber numberWithInt:self.delta] forKey:@"delta"];
    
    return rootDict;
}

@end
