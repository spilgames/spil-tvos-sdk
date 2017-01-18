//
//  Wallet.m
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "Wallet.h"
#import "GameDataController.h"
#import "PlayerDataController.h"
#import "UserProfile.h"
#import "JsonUtil.h"

@implementation Wallet

@synthesize currencies;
@synthesize offset;
@synthesize logic;

-(id)init {
    self = [super init];
    
    
    return self;
}

-(id)initWithDictionary:(NSDictionary*)data {
    self = [super init];
    
    self.offset = [data[@"offset"] intValue];
    self.logic = data[@"logic"];
    
    self.currencies = [NSMutableArray array];
    if (data[@"currencies"] != nil) {
        for (NSDictionary *dict in data[@"currencies"]) {
            PlayerCurrency *playerCurrency = [[PlayerCurrency alloc] initWithDictionary:dict];
            [self.currencies addObject:playerCurrency];
        }
    }
    
    return self;
}

-(NSDictionary*)toJSONObject {
    NSMutableDictionary *rootDict = [NSMutableDictionary dictionary];
    
    [rootDict setObject:[NSNumber numberWithInt:self.offset] forKey:@"offset"];
    
    if (self.logic != nil) {
        [rootDict setObject:self.logic forKey:@"logic"];
    }
    
    NSMutableArray *currencyArray = [NSMutableArray array];
    if (self.currencies != nil) {
        for (PlayerCurrency *currency in self.currencies) {
            [currencyArray addObject:[currency toJSONObject]];
        }
    }
    [rootDict setObject:currencyArray forKey:@"currencies"];
    
    return rootDict;
}

-(NSArray*)getCurrenciesJSONArray {
    NSMutableArray *currencyArray = [NSMutableArray array];
    if (self.currencies != nil) {
        for (PlayerCurrency *currency in self.currencies) {
            [currencyArray addObject:[currency toJSONObject]];
        }
    }
    return currencyArray;
}

-(NSString*)toJSONString {
    return [JsonUtil convertObjectToJson:[self toJSONObject]];
}

-(PlayerCurrency*)getCurrency:(int)id {
    for(int i = 0; i < [self.currencies count]; i++){
        PlayerCurrency *playerCurrency = [self.currencies objectAtIndex:i];
        if(playerCurrency.id == id){
            return playerCurrency;
        }
    }
    
    return nil;
}

-(NSArray*)getUpdatedCurrencies {
    NSMutableArray *result = [NSMutableArray array];
    
    for(int i = 0; i < currencies.count; i++){
        PlayerCurrency* currency = (PlayerCurrency*)[currencies objectAtIndex:i];
        
        if(currency.delta != 0) {
            [result addObject:[currency toJSONObject]];
        }
    }
    
    return result;
}

-(BOOL)hasEnoughCurrencyForBundle:(Bundle*)bundle {
    for (BundlePrice *bundlePrice in bundle.prices) {
        PlayerCurrency *playerCurrency = [[[PlayerDataController sharedInstance] getUserProfile].wallet getCurrency:bundlePrice.currencyId];
        
        if (playerCurrency == nil || playerCurrency.currentBalance < bundlePrice.value) {
            return false;
        }
    }
    return true;
}

-(void)reset {
    for(int i = 0; i < currencies.count; i++){
        PlayerCurrency* currency = (PlayerCurrency*)[currencies objectAtIndex:i];
        if (currency.currentBalance != 0) {
            currency.delta -= (currency.currentBalance - currency.initialValue);
            currency.currentBalance = currency.initialValue;
        }
    }
}

@end
