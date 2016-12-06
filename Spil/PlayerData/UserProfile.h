//
//  UserProfile.h
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Wallet.h"
#import "Inventory.h"
#import "JSONModel.h"

@protocol UserProfile
@end

@interface UserProfile : JSONModel

@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSString *facebookID;
@property (strong, nonatomic) NSString *playGamesID;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *gender;
@property (strong, nonatomic) NSString *age;
@property (strong, nonatomic) NSString *country;

@property (strong, nonatomic) Wallet *wallet;
@property (strong, nonatomic) Inventory *inventory;

-(id)init;

@end