//
//  JsonUtil.m
//  Spil
//
//  Created by Frank Slofstra on 23/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "JsonUtil.h"

@implementation JsonUtil

+(id)convertStringToObject:(NSString*) jsonString {
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

+(NSString*)convertObjectToJson:(id) object {
    if (object == nil) {
        return nil;
    }
    
    if ([object isKindOfClass:[NSNumber class]]) {
        return [object stringValue];
    }
    
    @try {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
        if (jsonData) {
            return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        } else {
            return nil;
        }
    } @catch (NSException *exception) {
        NSLog(@"JsonUtil EXCEPTION: %@", exception.description);
        return nil;
    }
}

+(NSString*)convertObjectToReadableJson:(id) object {
    if (object == nil) {
        return nil;
    }
    
    if ([object isKindOfClass:[NSNumber class]]) {
        return [object stringValue];
    }
    
    @try {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&error];
        if (jsonData) {
            return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        } else {
            return nil;
        }
    } @catch (NSException *exception) {
        NSLog(@"JsonUtil EXCEPTION: %@", exception.description);
        return nil;
    }
}

@end
