//
//  SpilConfigHandler.h
//  config
//
//  Created by Martijn van der Gun on 11/25/15.
//  Copyright © 2015 Company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SpilConfigHandler : NSObject

+(SpilConfigHandler*)sharedInstance;

-(NSDictionary*)getConfig;
-(id)getConfigValue:(NSString*)keyString;
-(void)storeConfig:(NSString*)jsonString;

@end