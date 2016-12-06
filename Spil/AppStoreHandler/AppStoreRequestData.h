//
//  AppStoreRequestData.h
//  Spil
//
//  Created by Frank Slofstra on 03/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
@import StoreKit;

@interface AppStoreRequestData : NSObject

@property (strong, nonatomic) SKProductsRequest *productRequest;
@property (strong, nonatomic) NSString *eventName;
@property (strong, nonatomic) NSMutableDictionary *eventParams;
@property (strong, nonatomic) NSString *productIdentifier;

-(id)initWithRequest:(SKProductsRequest*)productRequest withName:(NSString*)eventName withParams:(NSMutableDictionary*)eventParams withProductIdentifier:(NSString*)productIdentifier;

@end