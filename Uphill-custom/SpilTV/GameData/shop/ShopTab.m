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

-(id)initWithDictionary:(NSDictionary*)data {
    self = [super init];
    
    self.position = [data[@"position"] intValue];
    self.name = data[@"name"];

    self.entries = [NSMutableArray array];
    if (data[@"entries"] != nil) {
        for (NSDictionary *dict in data[@"entries"]) {
            ShopEntry *shopEntry = [[ShopEntry alloc] initWithDictionary:dict];
            [self.entries addObject:shopEntry];
        }
    }
    
    return self;
}

-(NSDictionary*)toJSONObject {
    NSMutableDictionary *rootDict = [NSMutableDictionary dictionary];
    
    [rootDict setObject:[NSNumber numberWithInt:self.position] forKey:@"position"];
    
    if (self.name != nil) {
        [rootDict setObject:self.name forKey:@"name"];
    }
    
    NSMutableArray *entryArray = [NSMutableArray array];
    if (self.entries != nil) {
        for (ShopEntry *entry in self.entries) {
            [entryArray addObject:[entry toJSONObject]];
        }
    }
    [rootDict setObject:entryArray forKey:@"entries"];
    
    return rootDict;
}

@end
