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
    self.amount = item.initialValue;
    self.delta = item.initialValue;
    self.initialValue = item.initialValue;
    
    return self;
}

-(id)initWithDictionary:(NSDictionary*)dict {
    self = [super initWithDictionary:dict];
    
    self.amount = [dict[@"amount"] intValue];
    self.delta = [dict[@"delta"] intValue];
    
    return self;
}

-(NSDictionary*)toJSONObject {
    NSMutableDictionary *rootDict = [super toJSONObject];
    
    [rootDict setObject:[NSNumber numberWithInt:self.amount] forKey:@"amount"];
    [rootDict setObject:[NSNumber numberWithInt:self.delta] forKey:@"delta"];
    
    return rootDict;
}

@end
