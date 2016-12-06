//
//  BundlePrice.h
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONModel.h"

@protocol BundlePrice
@end

@interface BundlePrice : JSONModel

@property (assign, nonatomic) int currencyId;
@property (assign, nonatomic) int value;

-(id)init;

@end
