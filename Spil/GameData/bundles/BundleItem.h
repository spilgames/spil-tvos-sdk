//
//  BundleItem.h
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONModel.h"

@protocol BundleItem
@end

@interface BundleItem : JSONModel

@property (assign, nonatomic) int id;
@property (assign, nonatomic) int amount;

-(id)init;

@end
