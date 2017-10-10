//
//  UserProfile.m
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "UserProfile.h"
#import "JsonUtil.h"

@implementation UserProfile

@synthesize userID;
@synthesize facebookID;
@synthesize playGamesID;
@synthesize username;
@synthesize gender;
@synthesize age;
@synthesize country;

@synthesize wallet;
@synthesize inventory;

-(id)initWithDictionary:(NSDictionary*)dict {
    self = [super init];
    
    self.userID = dict[@"userID"];
    self.facebookID = dict[@"facebookID"];
    self.playGamesID = dict[@"playGamesID"];
    self.username = dict[@"username"];
    self.gender = dict[@"gender"];
    self.age = dict[@"age"];
    self.country = dict[@"country"];
    
    self.wallet = [[Wallet alloc] initWithDictionary:dict[@"wallet"]];
    self.inventory = [[Inventory alloc] initWithDictionary:dict[@"inventory"]];
    
    return self;
}

-(NSDictionary*)toJSONObject {
    NSMutableDictionary *rootDict = [NSMutableDictionary dictionary];
    
    if (self.userID != nil) {
        [rootDict setObject:self.userID forKey:@"userID"];
    }
    
    if (self.facebookID != nil) {
        [rootDict setObject:self.facebookID forKey:@"facebookID"];
    }
    
    if (self.playGamesID != nil) {
        [rootDict setObject:self.playGamesID forKey:@"playGamesID"];
    }
    
    if (self.username != nil) {
        [rootDict setObject:self.username forKey:@"username"];
    }
    
    if (self.gender != nil) {
        [rootDict setObject:self.gender forKey:@"gender"];
    }
    
    if (self.age != nil) {
        [rootDict setObject:self.age forKey:@"age"];
    }
    
    if (self.country != nil) {
        [rootDict setObject:self.country forKey:@"country"];
    }

    [rootDict setObject:[self.wallet toJSONObject] forKey:@"wallet"];
    [rootDict setObject:[self.inventory toJSONObject] forKey:@"inventory"];
    
    return rootDict;
}

-(NSString*)toJSONString {
    return [JsonUtil convertObjectToJson:[self toJSONObject]];
}

@end
