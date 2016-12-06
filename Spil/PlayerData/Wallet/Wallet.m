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

@implementation Wallet

@synthesize currencies;
@synthesize offset;
@synthesize logic;

-(id)init {
    self = [super init];
    
    return self;
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

+(BOOL)propertyIsOptional:(NSString*)propertyName {
    return YES;
}

-(NSArray*)getUpdatedCurrencies {
    NSMutableArray *result = [NSMutableArray array];
    
    for(int i = 0; i < currencies.count; i++){
        PlayerCurrency* currency = (PlayerCurrency*)[currencies objectAtIndex:i];
        
        if(currency.delta != 0) {
            [result addObject:[currency toDictionary]];
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

@end