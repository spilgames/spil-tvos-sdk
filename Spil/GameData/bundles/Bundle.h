//
//  Bundle.h
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONModel.h"
#import "BundleItem.h"
#import "BundlePrice.h"

@protocol Bundle
@end

@interface Bundle : JSONModel

@property (assign, nonatomic) int id;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSMutableArray<BundlePrice> *prices; // Array of BundlePrice's
@property (strong, nonatomic) NSMutableArray<BundleItem> *items; // Array of BundleItem's

-(id)init;

@end
