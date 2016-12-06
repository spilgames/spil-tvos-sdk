//
//  SpilActionHandler.h
//  trackerSample
//
//  Created by Martijn van der Gun on 5/28/15.
//  Copyright (c) 2015 Martijn van der Gun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SpilActionHandler : NSObject

+(void)handleAction:(NSDictionary*)action withCallBackUID:(NSString*)callbackUID;
+(void)handleAction:(NSDictionary*)action withResponse:(void (^)(id response))block;

@end