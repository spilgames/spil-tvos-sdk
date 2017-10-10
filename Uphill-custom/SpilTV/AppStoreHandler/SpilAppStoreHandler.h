//
//  SpilAppStoreHandler.h
//  Spil
//
//  Created by Frank Slofstra on 03/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface SpilAppStoreHandler : NSObject<SKProductsRequestDelegate> {
    
}

+(SpilAppStoreHandler*)sharedInstance;

-(void)requestAppStoreItemForEvent:(NSString*)name withParams:(NSDictionary*)params;

@end
