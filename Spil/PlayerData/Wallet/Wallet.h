//
//  Wallet.h
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayerCurrency.h"
#import "JSONModel.h"
#import "Bundle.h"

@protocol Wallet
@end

@interface Wallet : JSONModel

@property (strong, nonatomic) NSMutableArray <PlayerCurrency> *currencies;
@property (nonatomic) int offset;
@property (strong, nonatomic) NSString* logic;

-(id)init;

-(PlayerCurrency*)getCurrency:(int)id;

-(NSArray*)getUpdatedCurrencies;

-(BOOL)hasEnoughCurrencyForBundle:(Bundle*)bundle;

@end