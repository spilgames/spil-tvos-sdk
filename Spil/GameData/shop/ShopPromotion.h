//
//  ShopPromotion.h
//  Spil
//
//  Created by Frank Slofstra on 14/06/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BundlePrice.h"
#import "JSONModel.h"

@protocol ShopPromotion
@end

@interface ShopPromotion : JSONModel

@property (nonatomic, assign) int bundleId;
@property (nonatomic, assign) int amount;
@property (nonatomic, strong) NSMutableArray<BundlePrice> *prices;
@property (nonatomic, strong) NSString* discount;
@property (nonatomic, strong) NSString* startDate;
@property (nonatomic, strong) NSString* endDate;

-(id)init;

@end