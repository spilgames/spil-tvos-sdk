//
//  GameData.h
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONModel.h"
#import "Item.h"
#import "Currency.h"
#import "Bundle.h"
#import "ShopEntry.h"
#import "ShopTab.h"
#import "ShopPromotion.h"

@protocol GameData
@end

@interface GameData : JSONModel

@property (strong, nonatomic) NSMutableArray<Item> *items;
@property (strong, nonatomic) NSMutableArray<Currency> *currencies;
@property (strong, nonatomic) NSMutableArray<Bundle> *bundles;
@property (strong, nonatomic) NSMutableArray<ShopTab> *shop;
@property (strong, nonatomic) NSMutableArray<ShopPromotion> *promotions;

-(id)init;

@end
