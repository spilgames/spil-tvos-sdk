//
//  Inventory.h
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayerItem.h"
#import "JSONModel.h"

@protocol Inventory
@end

@interface Inventory : JSONModel

@property (strong, nonatomic) NSMutableArray<PlayerItem> *items;
@property (nonatomic) int offset;
@property (strong, nonatomic) NSString* logic;

-(id)init;

-(void)updateItem:(PlayerItem*)item;

-(NSArray*)getUpdatedItems;

-(PlayerItem*)getItem:(int)id;

@end