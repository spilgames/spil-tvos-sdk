//
//  GameData.m
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "GameData.h"
#import "JsonUtil.h"

@implementation GameData

@synthesize items;
@synthesize currencies;
@synthesize bundles;
@synthesize shop;
@synthesize promotions;

-(id)initWithDictionary:(NSDictionary*)data {
    self = [super init];
    
    self.items = [NSMutableArray array];
    if (data[@"items"] != nil) {
        for (NSDictionary *dict in data[@"items"]) {
            Item *item = [[Item alloc] initWithDictionary:dict];
            [self.items addObject:item];
        }
    }
    
    self.currencies = [NSMutableArray array];
    if (data[@"currencies"] != nil) {
        for (NSDictionary *dict in data[@"currencies"]) {
            Currency *currency = [[Currency alloc] initWithDictionary:dict];
            [self.currencies addObject:currency];
        }
    }
    
    self.bundles = [NSMutableArray array];
    if (data[@"bundles"] != nil) {
        for (NSDictionary *dict in data[@"bundles"]) {
            Bundle *bundle = [[Bundle alloc] initWithDictionary:dict];
            [self.bundles addObject:bundle];
        }
    }
    
    self.shop = [NSMutableArray array];
    if (data[@"shop"] != nil) {
        for (NSDictionary *dict in data[@"shop"]) {
            ShopTab *shopTab = [[ShopTab alloc] initWithDictionary:dict];
            [self.shop addObject:shopTab];
        }
    }
    
    self.promotions = [NSMutableArray array];
    if (data[@"promotions"] != nil) {
        for (NSDictionary *dict in data[@"promotions"]) {
            ShopPromotion *shopPromotion = [[ShopPromotion alloc] initWithDictionary:dict];
            [self.promotions addObject:shopPromotion];
        }
    }
    
    return self;
}

-(NSString*)toJSONString {
    NSMutableDictionary *rootDict = [NSMutableDictionary dictionary];
    
    NSMutableArray *itemArray = [NSMutableArray array];
    if (self.items != nil) {
        for (Item *item in self.items) {
            [itemArray addObject:[item toJSONObject]];
        }
    }
    [rootDict setObject:itemArray forKey:@"items"];
    
    NSMutableArray *currencyArray = [NSMutableArray array];
    if (self.currencies != nil) {
        for (Currency *currency in self.currencies) {
            [currencyArray addObject:[currency toJSONObject]];
        }
    }
    [rootDict setObject:currencyArray forKey:@"currencies"];
    
    NSMutableArray *bundleArray = [NSMutableArray array];
    if (self.bundles != nil) {
        for (Bundle *bundle in self.bundles) {
            [bundleArray addObject:[bundle toJSONObject]];
        }
    }
    [rootDict setObject:bundleArray forKey:@"bundles"];
    
    NSMutableArray *shopArray = [NSMutableArray array];
    if (self.shop != nil) {
        for (ShopTab *shopTab in self.shop) {
            [shopArray addObject:[shopTab toJSONObject]];
        }
    }
    [rootDict setObject:shopArray forKey:@"shop"];
    
    NSMutableArray *promotionsArray = [NSMutableArray array];
    if (self.promotions != nil) {
        for (ShopPromotion *shopPromotion in self.promotions) {
            [promotionsArray addObject:[shopPromotion toJSONObject]];
        }
    }
    [rootDict setObject:promotionsArray forKey:@"promotions"];
    
    return [JsonUtil convertObjectToJson:rootDict];
}

-(NSString*)getShopJSONString {
    NSMutableArray *shopArray = [NSMutableArray array];
    if (self.shop != nil) {
        for (ShopTab *shopTab in self.shop) {
            [shopArray addObject:[shopTab toJSONObject]];
        }
    }
    return [JsonUtil convertObjectToJson:shopArray];
}

-(NSString*)getPromotionsJSONString {
    NSMutableArray *promotionsArray = [NSMutableArray array];
    if (self.promotions != nil) {
        for (ShopPromotion *shopPromotion in self.promotions) {
            [promotionsArray addObject:[shopPromotion toJSONObject]];
        }
    }
    return [JsonUtil convertObjectToJson:promotionsArray];
}

@end
