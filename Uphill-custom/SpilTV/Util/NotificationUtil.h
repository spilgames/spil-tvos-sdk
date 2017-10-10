//
//  NotificationUtil.h
//  Spil
//
//  Created by Frank Slofstra on 03/10/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NotificationUtil : NSObject

+(void)send:(NSString *)name;
+(void)send:(NSString *)name message:(NSString*)message;
+(void)send:(NSString *)name data:(id)data;

@end
