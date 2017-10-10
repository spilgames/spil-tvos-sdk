//
//  NSString+Extensions.h
//  Spil
//
//  Created by Frank Slofstra on 23/06/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Extensions)

- (NSString *)urlencode;
- (NSString *)urldecode;
+ (NSString *)base64StringFromData:(NSData *)inputData;

@end
