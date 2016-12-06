//
//  Util.h
//  Spil
//
//  Created by Frank Slofstra on 18/08/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Util : NSObject

+(UIColor*)colorFromHexString:(NSString *)hexString;
+(BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate;
+(NSDate*)parseDate:(NSString*)string;
+(NSString*)urlEncode:(NSString*)input;
+(NSString*)urlDecode:(NSString*)input;

@end
