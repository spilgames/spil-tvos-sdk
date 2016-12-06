//
//  ShopTab.h
//  Spil
//
//  Created by Frank Slofstra on 14/06/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONModel.h"
#import "ShopEntry.h"

@protocol ShopTab
@end

@interface ShopTab : JSONModel

@property (nonatomic, assign) int position;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSMutableArray<ShopEntry> *entries;

-(id)init;

@end