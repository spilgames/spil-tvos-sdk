//
//  GameData.h
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Item.h"
#import "Currency.h"
#import "Bundle.h"
#import "ShopTab.h"
#import "ShopPromotion.h"

@interface GameData : NSObject

@property (strong, nonatomic) NSMutableArray *items; // Item
@property (strong, nonatomic) NSMutableArray *currencies; // Currency
@property (strong, nonatomic) NSMutableArray *bundles; // Bundle
@property (strong, nonatomic) NSMutableArray *shop; // ShopTab
@property (strong, nonatomic) NSMutableArray *promotions; // ShopPromotion

-(id)initWithDictionary:(NSDictionary*)data;

-(NSString*)toJSONString;

-(NSString*)getShopJSONString;
-(NSString*)getPromotionsJSONString;

@end
