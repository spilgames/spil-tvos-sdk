//
//  ShopEntry.m
//  Spil
//
//  Created by Frank Slofstra on 14/06/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "ShopEntry.h"

@implementation ShopEntry

@synthesize bundleId;
@synthesize label;
@synthesize position;

-(id)initWithDictionary:(NSDictionary*)dict {
    self = [super init];
    
    self.bundleId = [dict[@"bundleId"] intValue];
    self.label = dict[@"label"];
    self.position = [dict[@"position"] intValue];
    
    return self;
}

-(NSDictionary*)toJSONObject {
    NSMutableDictionary *rootDict = [NSMutableDictionary dictionary];
    
    [rootDict setObject:[NSNumber numberWithInt:self.bundleId] forKey:@"bundleId"];
    
    if (self.label != nil) {
        [rootDict setObject:self.label forKey:@"label"];
    }
    
    [rootDict setObject:[NSNumber numberWithInt:self.position] forKey:@"position"];
    
    return rootDict;
}

@end
