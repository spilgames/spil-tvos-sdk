//
//  AppStoreRequestData.m
//  Spil
//
//  Created by Frank Slofstra on 03/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "AppStoreRequestData.h"

@implementation AppStoreRequestData

@synthesize productRequest;
@synthesize eventName;
@synthesize eventParams;
@synthesize productIdentifier;

-(id)initWithRequest:(SKProductsRequest*)request withName:(NSString*)name withParams:(NSMutableDictionary*)params withProductIdentifier:(NSString*)productId {
    self = [super init];
    
    self.productRequest = request;
    self.eventName = name;
    self.eventParams = params;
    self.productIdentifier = productId;
    
    return self;
}

@end