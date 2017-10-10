//
//  SpilPackageHandler.h
//
//  Created by Frank Slofstra on 18/04/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpilPackageHandler : NSObject

+(SpilPackageHandler*)sharedInstance;

-(NSArray*)getAllPromotions;
-(NSArray*)getAllPackages;
-(id)getPackageByID:(NSString*)packageId;
-(id)getPromotionByID:(NSString*)promotionId;
-(void)requestPackages;
-(void)storePackages:(NSDictionary*)data;

@end
