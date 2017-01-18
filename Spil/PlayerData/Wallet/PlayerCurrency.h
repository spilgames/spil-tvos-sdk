//
//  PlayerCurrency.h
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Currency.h"

@interface PlayerCurrency : Currency

@property (nonatomic) int currentBalance;
@property (nonatomic) int delta;

-(id)init;
-(id)initWithCurrency:(Currency*)currency;
-(id)initWithDictionary:(NSDictionary*)dict;

-(NSDictionary*)toJSONObject;

@end
