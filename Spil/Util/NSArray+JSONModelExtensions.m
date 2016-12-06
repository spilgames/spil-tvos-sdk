//
//  NSArray+JSONModelExtensions.m
//  Spil
//
//  Created by Frank Slofstra on 16/06/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "NSArray+JSONModelExtensions.h"

@implementation NSArray (JSONModelExtensions)

- (NSString*)toJSONString {
    NSMutableArray* jsonObjects = [NSMutableArray new];
    for ( id obj in self )
        [jsonObjects addObject:[obj toJSONString]];
    return [NSString stringWithFormat:@"[%@]", [jsonObjects componentsJoinedByString:@","]];
}

@end
