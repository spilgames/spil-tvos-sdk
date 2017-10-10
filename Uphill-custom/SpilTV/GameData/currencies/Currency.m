//
//  Currency.m
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "Currency.h"

@implementation Currency

@synthesize id;
@synthesize name;
@synthesize type;
@synthesize initialValue;

-(id)initWithDictionary:(NSDictionary*)dict {
    self = [super init];
    
    self.id = [dict[@"id"] intValue];
    self.name = dict[@"name"];
    self.type = [dict[@"type"] intValue];
    self.initialValue = [dict[@"initialValue"] intValue];
    
    return self;
}

-(NSMutableDictionary*)toJSONObject {
    NSMutableDictionary *rootDict = [NSMutableDictionary dictionary];
    
    [rootDict setObject:[NSNumber numberWithInt:self.id] forKey:@"id"];
    
    if (self.name != nil) {
        [rootDict setObject:self.name forKey:@"name"];
    }

    [rootDict setObject:[NSNumber numberWithInt:self.type] forKey:@"type"];
    [rootDict setObject:[NSNumber numberWithInt:self.initialValue] forKey:@"initialValue"];
    
    return rootDict;
}

@end
