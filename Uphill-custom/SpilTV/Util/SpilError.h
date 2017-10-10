//
//  SpilError.h
//  Spil
//
//  Created by Frank Slofstra on 08/06/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpilError : NSObject

@property (nonatomic, assign) int id;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *message;

-(id)initWithId:(int)_id name:(NSString*)_name message:(NSString*)_message;

-(NSString*)toJson;

+(SpilError*)LoadFailed:(NSString*)message;
+(SpilError*)ItemNotFound:(NSString*)message;
+(SpilError*)CurrencyNotFound:(NSString*)message;
+(SpilError*)BundleNotFound:(NSString*)message;
+(SpilError*)WalletNotFound:(NSString*)message;
+(SpilError*)InventoryNotFound:(NSString*)message;
+(SpilError*)NotEnoughCurrency:(NSString*)message;
+(SpilError*)ItemAmountToLow:(NSString*)message;
+(SpilError*)CurrencyOperationFailed:(NSString*)message;
+(SpilError*)ItemOperationFailed:(NSString*)message;
+(SpilError*)BundleOperationFailed:(NSString*)message;
+(SpilError*)PublicGameStateOperationFailed:(NSString*)message;
+(SpilError*)GameStateServerError:(NSString*)message;
+(SpilError*)WebServerError:(NSString*)message;

@end
