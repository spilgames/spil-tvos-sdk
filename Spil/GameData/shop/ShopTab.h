//
//  ShopTab.h
//  Spil
//
//  Created by Frank Slofstra on 14/06/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShopEntry.h"

@interface ShopTab : NSObject

@property (nonatomic, assign) int position;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSMutableArray *entries; // ShopEntry

-(id)initWithDictionary:(NSDictionary*)data;

-(NSDictionary*)toJSONObject;

@end
