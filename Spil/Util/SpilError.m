//
//  SpilError.m
//  Spil
//
//  Created by Frank Slofstra on 08/06/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "SpilError.h"
#import "JsonUtil.h"

@implementation SpilError

@synthesize id;
@synthesize name;
@synthesize message;

-(id)initWithId:(int)_id name:(NSString*)_name message:(NSString*)_message {
    self = [super init];
    
    self.id = _id;
    self.name = _name;
    self.message = _message;
    
    return self;
}

-(NSString*)toJson {
    NSDictionary *dict = @{ @"id": [NSNumber numberWithInt:self.id], @"name": self.name, @"message": self.message };
    return [JsonUtil convertObjectToJson:dict];
}

+(SpilError*)LoadFailed:(NSString*)message {
    return [[SpilError alloc] initWithId:1 name:@"LoadFailed" message:message];
}

+(SpilError*)ItemNotFound:(NSString*)message {
    return [[SpilError alloc] initWithId:2 name:@"ItemNotFound" message:message];
}

+(SpilError*)CurrencyNotFound:(NSString*)message {
    return [[SpilError alloc] initWithId:3 name:@"CurrencyNotFound" message:message];
}

+(SpilError*)BundleNotFound:(NSString*)message {
    return [[SpilError alloc] initWithId:4 name:@"BundleNotFound" message:message];
}

+(SpilError*)WalletNotFound:(NSString*)message {
    return [[SpilError alloc] initWithId:5 name:@"WalletNotFound" message:message];
}

+(SpilError*)InventoryNotFound:(NSString*)message {
    return [[SpilError alloc] initWithId:6 name:@"InventoryNotFound" message:message];
}

+(SpilError*)NotEnoughCurrency:(NSString*)message {
    return [[SpilError alloc] initWithId:7 name:@"NotEnoughCurrency" message:message];
}

+(SpilError*)ItemAmountToLow:(NSString*)message {
    return [[SpilError alloc] initWithId:8 name:@"ItemAmountToLow" message:message];
}

+(SpilError*)CurrencyOperationFailed:(NSString*)message {
    return [[SpilError alloc] initWithId:9 name:@"CurrencyOperation" message:message];
}

+(SpilError*)ItemOperationFailed:(NSString*)message {
    return [[SpilError alloc] initWithId:10 name:@"ItemOperation" message:message];
}

+(SpilError*)BundleOperationFailed:(NSString*)message {
    return [[SpilError alloc] initWithId:11 name:@"BundleOperation" message:message];
}

+(SpilError*)PublicGameStateOperationFailed:(NSString*)message {
    return [[SpilError alloc] initWithId:12 name:@"PublicGameStateOperation" message:message];
}

+(SpilError*)GameStateServerError:(NSString*)message {
    return [[SpilError alloc] initWithId:13 name:@"GameStateServerError" message:message];
}

+(SpilError*)WebServerError:(NSString*)message {
    return [[SpilError alloc] initWithId:14 name:@"WebServerError" message:message];
}

@end
