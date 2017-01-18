//
//  ShopPromotion.m
//  Spil
//
//  Created by Frank Slofstra on 14/06/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "ShopPromotion.h"

@implementation ShopPromotion

@synthesize bundleId;
@synthesize amount;
@synthesize prices;
@synthesize discount;
@synthesize startDate;
@synthesize endDate;

-(id)initWithDictionary:(NSDictionary*)data {
    self = [super init];
    
    self.bundleId = [data[@"bundleId"] intValue];
    self.amount = [data[@"amount"] intValue];
    self.discount = data[@"discount"];
    self.startDate = data[@"startDate"];
    self.endDate = data[@"endDate"];
    
    self.prices = [NSMutableArray array];
    if (data[@"prices"] != nil) {
        for (NSDictionary *dict in data[@"prices"]) {
            BundlePrice *bundlePrice = [[BundlePrice alloc] initWithDictionary:dict];
            [self.prices addObject:bundlePrice];
        }
    }
    
    return self;
}

-(NSDictionary*)toJSONObject {
    NSMutableDictionary *rootDict = [NSMutableDictionary dictionary];
    
    [rootDict setObject:[NSNumber numberWithInt:self.bundleId] forKey:@"bundleId"];
    [rootDict setObject:[NSNumber numberWithInt:self.amount] forKey:@"amount"];
    
    if (self.discount != nil) {
        [rootDict setObject:self.discount forKey:@"discount"];
    }
    
    if (self.startDate != nil) {
        [rootDict setObject:self.startDate forKey:@"startDate"];
    }
    
    if (self.endDate != nil) {
        [rootDict setObject:self.endDate forKey:@"endDate"];
    }
    
    NSMutableArray *priceArray = [NSMutableArray array];
    if (self.prices != nil) {
        for (BundlePrice *price in self.prices) {
            [priceArray addObject:[price toJSONObject]];
        }
    }
    [rootDict setObject:priceArray forKey:@"prices"];
    
    return rootDict;
}

@end
