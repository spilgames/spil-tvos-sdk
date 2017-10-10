//
//  BundlePrice.m
//  Spil
//
//  Created by Frank Slofstra on 17/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "BundlePrice.h"

@implementation BundlePrice

@synthesize currencyId;
@synthesize value;

-(id)initWithDictionary:(NSDictionary*)dict {
    self = [super init];
    
    self.currencyId = [dict[@"currencyId"] intValue];
    self.value = [dict[@"value"] intValue];
    
    return self;
}

-(NSDictionary*)toJSONObject {
    NSMutableDictionary *rootDict = [NSMutableDictionary dictionary];
    
    [rootDict setObject:[NSNumber numberWithInt:self.currencyId] forKey:@"currencyId"];
    [rootDict setObject:[NSNumber numberWithInt:self.value] forKey:@"value"];
    
    return rootDict;
}

@end
