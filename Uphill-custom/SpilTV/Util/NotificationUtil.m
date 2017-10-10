//
//  NotificationUtil.m
//  Spil
//
//  Created by Frank Slofstra on 03/10/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "NotificationUtil.h"

@implementation NotificationUtil

+(void)send:(NSString *)name {
    NSDictionary *userInfo = @{@"event" : name};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
}

+(void)send:(NSString *)name message:(NSString*)message {
    NSDictionary *userInfo = @{@"event" : name, @"message" : message };
    [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
}

+(void)send:(NSString *)name data:(id)data {
    NSDictionary *userInfo = @{@"event" : name, @"data" : data };
    [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
}

@end
