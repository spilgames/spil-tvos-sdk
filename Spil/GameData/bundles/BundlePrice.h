//
//  BundlePrice.h
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BundlePrice : NSObject

@property (assign, nonatomic) int currencyId;
@property (assign, nonatomic) int value;

-(id)initWithDictionary:(NSDictionary*)dict;

-(NSDictionary*)toJSONObject;

@end
