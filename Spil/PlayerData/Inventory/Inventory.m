//
//  Inventory.m
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "Inventory.h"
#import "GameDataController.h"

@implementation Inventory

@synthesize items;
@synthesize offset;
@synthesize logic;

-(id)init {
    self = [super init];
    
    return self;
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
            [result addObject:[item toDictionary]];
        }
    }
    
    return result;
}

+(BOOL)propertyIsOptional:(NSString*)propertyName {
    return YES;
}

@end