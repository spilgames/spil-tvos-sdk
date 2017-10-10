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

-(id)initWithDictionary:(NSDictionary*)data {
    self = [super init];
    
    self.id = [data[@"id"] intValue];
    self.name = data[@"name"];
    
    self.prices = [NSMutableArray array];
    if (data[@"prices"] != nil) {
        for (NSDictionary *dict in data[@"prices"]) {
            BundlePrice *bundlePrice = [[BundlePrice alloc] initWithDictionary:dict];
            [self.prices addObject:bundlePrice];
        }
    }
    
    self.items = [NSMutableArray array];
    if (data[@"items"] != nil) {
        for (NSDictionary *dict in data[@"items"]) {
            BundleItem *bundleItem = [[BundleItem alloc] initWithDictionary:dict];
            [self.items addObject:bundleItem];
        }
    }
    
    return self;
}

-(NSDictionary*)toJSONObject {
    NSMutableDictionary *rootDict = [NSMutableDictionary dictionary];
    
    [rootDict setObject:[NSNumber numberWithInt:self.id] forKey:@"id"];
    
    if (self.name != nil) {
        [rootDict setObject:self.name forKey:@"name"];
    }
    
    NSMutableArray *priceArray = [NSMutableArray array];
    if (self.prices != nil) {
        for (BundlePrice *price in self.prices) {
            [priceArray addObject:[price toJSONObject]];
        }
    }
    [rootDict setObject:priceArray forKey:@"prices"];
    
    NSMutableArray *itemArray = [NSMutableArray array];
    if (self.items != nil) {
        for (BundleItem *item in self.items) {
            [itemArray addObject:[item toJSONObject]];
        }
    }
    [rootDict setObject:itemArray forKey:@"items"];
    
    return rootDict;
}

-(NSArray*)getItemsJSONArray {
    NSMutableArray *itemArray = [NSMutableArray array];
    if (self.items != nil) {
        for (BundleItem *item in self.items) {
            [itemArray addObject:[item toJSONObject]];
        }
    }
    return itemArray;
}

-(NSArray*)getPricesJSONArray {
    NSMutableArray *priceArray = [NSMutableArray array];
    if (self.prices != nil) {
        for (BundlePrice *price in self.prices) {
            [priceArray addObject:[price toJSONObject]];
        }
    }
    return priceArray;
}

@end
