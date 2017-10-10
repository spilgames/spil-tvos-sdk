//
//  Util.m
//  Spil
//
//  Created by Frank Slofstra on 18/08/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "Util.h"

@implementation Util

+(UIColor*)colorFromHexString:(NSString *)hexString {
    if (hexString == nil) {
        return [UIColor blackColor];
    }
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

+(BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate {
    if (beginDate == nil || endDate == nil) {
        return NO;
    }
    
    if ([date compare:beginDate] == NSOrderedAscending) {
        return NO;
    }
    if ([date compare:endDate] == NSOrderedDescending) {
        return NO;
    }
    
    return YES;
}

+(NSDate*)parseDate:(NSString*)string {
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [formatter dateFromString:string];
    return date;
}

+ (NSString *)urlEncode:(NSString*)input {
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[input UTF8String];
    int sourceLen = (int)strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

+(NSString*)urlDecode:(NSString*)input {
    return (__bridge NSString *) CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef) input, CFSTR(""), kCFStringEncodingUTF8);
}

@end
