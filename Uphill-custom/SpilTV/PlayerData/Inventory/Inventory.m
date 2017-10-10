//
//  Inventory.m
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "Inventory.h"
#import "GameDataController.h"
#import "JsonUtil.h"

@implementation Inventory

@synthesize items;
@synthesize offset;
@synthesize logic;

-(id)init {
    self = [super init];
    
    return self;
}

-(id)initWithDictionary:(NSDictionary*)data {
    self = [super init];
    
    self.offset = [data[@"offset"] intValue];
    self.logic = data[@"logic"];
    
    self.items = [NSMutableArray array];
    if (data[@"items"] != nil) {
        for (NSDictionary *dict in data[@"items"]) {
            PlayerItem *playerItem = [[PlayerItem alloc] initWithDictionary:dict];
            [self.items addObject:playerItem];
        }
    }
    
    return self;
}

-(NSDictionary*)toJSONObject {
    NSMutableDictionary *rootDict = [NSMutableDictionary dictionary];
    
    [rootDict setObject:[NSNumber numberWithInt:self.offset] forKey:@"offset"];
    
    if (self.logic != nil) {
        [rootDict setObject:self.logic forKey:@"logic"];
    }
    
    NSMutableArray *itemArray = [NSMutableArray array];
    if (self.items != nil) {
        for (PlayerItem *item in self.items) {
            [itemArray addObject:[item toJSONObject]];
        }
    }
    [rootDict setObject:itemArray forKey:@"items"];
    
    return rootDict;
}

-(NSArray*)getItemsJSONArray {
    NSMutableArray *itemArray = [NSMutableArray array];
    if (self.items != nil) {
        for (PlayerItem *item in self.items) {
            [itemArray addObject:[item toJSONObject]];
        }
    }
    return itemArray;
}

-(NSString*)toJSONString {
    return [JsonUtil convertObjectToJson:[self toJSONObject]];
}

-(void)updateItem:(PlayerItem*)item {
    if([items count ] < 1){
        for(int i = 0; i < [items count]; i++){
            PlayerItem *pd = [items objectAtIndex:i];
            if(pd.id == item.id){
                [items removeObjectAtIndex:i];
                return;
            }
        }
    } else {
        for(int i = 0; i < [items count]; i++){
            PlayerItem *pd = [items objectAtIndex:i];
            if(pd.id == item.id){
                [items removeObjectAtIndex:i];
                [items addObject:item];
                return;
            }
        }
    }
}

-(PlayerItem*)getItem:(int)id {
    for(int i = 0; i < [items count]; i++){
        PlayerItem *pd = [items objectAtIndex:i];
        if(pd.id == id){
            return pd;
        }
    }
    return nil;
}

-(NSArray*)getUpdatedItems {
    NSMutableArray *result = [NSMutableArray array];
    
    for(int i = 0; i < items.count; i++){
        PlayerItem* item = (PlayerItem*)[items objectAtIndex:i];
        
        if(item.delta != 0) {
            [result addObject:[item toJSONObject]];
        }
    }
    
    return result;
}

-(void)reset {
    for(int i = 0; i < items.count; i++){
        PlayerItem* item = (PlayerItem*)[items objectAtIndex:i];
        if (item.amount != 0) {
            item.delta -= (item.amount - item.initialValue);
            item.amount = item.initialValue;
        }
    }
}

@end
