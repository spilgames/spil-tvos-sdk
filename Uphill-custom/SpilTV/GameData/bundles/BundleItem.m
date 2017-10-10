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

-(id)initWithDictionary:(NSDictionary*)dict {
    self = [super init];
    
    self.id = [dict[@"id"] intValue];
    self.amount = [dict[@"amount"] intValue];
    
    return self;
}

-(NSDictionary*)toJSONObject {
    NSMutableDictionary *rootDict = [NSMutableDictionary dictionary];
    
    [rootDict setObject:[NSNumber numberWithInt:self.id] forKey:@"id"];
    [rootDict setObject:[NSNumber numberWithInt:self.amount] forKey:@"amount"];
    
    return rootDict;
}

@end
