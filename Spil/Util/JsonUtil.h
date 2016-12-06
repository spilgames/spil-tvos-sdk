//
//  JsonUtil.h
//  Spil
//
//  Util class to convert foundation objects to and from json.
//  It does not support serialization, use JSONModel instead.
//
//  Created by Frank Slofstra on 23/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JsonUtil : NSObject

+(id)convertStringToObject:(NSString*) jsonString;
+(NSString*)convertObjectToJson:(id) object;

@end