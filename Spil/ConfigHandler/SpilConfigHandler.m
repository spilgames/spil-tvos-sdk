//
//  SpilConfigHandler.m
//  config
//
//  Created by Martijn van der Gun on 11/25/15.
//  Copyright © 2015 Company. All rights reserved.
//

#import "SpilConfigHandler.h"
#import "SpilEventTracker.h"
#import "JsonUtil.h"

@implementation SpilConfigHandler

static SpilConfigHandler* sharedInstance;

+ (SpilConfigHandler*)sharedInstance {
    static SpilConfigHandler *instance = nil;
    if (instance == nil) {
        // structure used to test whether the block has completed or not
        static dispatch_once_t p;
        dispatch_once(&p, ^{
            instance = [[SpilConfigHandler alloc] init];
        });
    }
    
    return instance;
}

-(id)init {
    self = [super init];
    
    NSDictionary *config = [self getConfig];
    if (config != nil) {
        NSLog(@"[SpilConfigHandler] Stored config found: %@", [JsonUtil convertObjectToJson:config]);
    } else {
        NSLog(@"[SpilConfigHandler] No stored config found");
    }
    
    return self;
}


-(NSDictionary*)getConfig {
    // get the current config
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *config = [defaults objectForKey:@"com.spilgames.app.config"];

    // if empty write the default value
    if(config == nil) {
        // get the config from the json file.
        NSError *error = nil;
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"defaultGameConfig" ofType:@"json"];
        
        NSData *dataFromFile = [NSData dataWithContentsOfFile:filePath];
        if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
            //NSLog(@"[SpilConfigHandler] dataFromFile %@",dataFromFile);
        }
        if(dataFromFile == NULL) {
            if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
                NSLog(@"[SpilConfigHandler] Spil config seems missing!");
            }
            return @{};
        }
        
        NSDictionary *data = [NSJSONSerialization JSONObjectWithData:dataFromFile options:kNilOptions error:&error];
        
        // check json data
        if (data != nil) {
            NSLog(@"[SpilConfigHandler] default json data found: %@", data);
            
            // store it
            [defaults setObject:data forKey:@"com.spilgames.app.config"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            config = data;
        } else {
            NSLog(@"[SpilConfigHandler] json data is invalid");
        }
    }
    
    return config;
}

// gets a value for a key from the first hiargy
-(id)getConfigValue:(NSString*)keyString{
    if (keyString == nil || [keyString isEqualToString:@""]) {
        return @"";
    }
    
    NSDictionary *config = [self getConfig];
    if ([config objectForKey:keyString] != nil) {
        return [config objectForKey:keyString];
    }
    return @"";
}

-(void)storeConfig:(NSDictionary*)config {
    if(config == nil) {
        return;
    }
    
    // check for valid NSDictionary
    if ([[config allKeys] count] > 0) {
        if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
            NSLog(@"[SpilConfigHandler] Spil storing json data from server: %@",config);
        }
        
        // store it
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:config forKey:@"com.spilgames.app.config"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        NSDictionary *userInfo = @{@"event" : @"configUpdated"};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:userInfo];
    } else {
        if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
            NSLog(@"[SpilConfigHandler] json config dictionary is empty");
        }
    }
}

@end
