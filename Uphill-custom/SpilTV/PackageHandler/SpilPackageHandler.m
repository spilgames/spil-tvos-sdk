//
//  SpilPackageHandler.m
//  Spil
//
//  Created by Frank Slofstra on 18/04/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "SpilPackageHandler.h"
#import "SpilEventTracker.h"

@interface SpilPackageHandler ()

@end

@implementation SpilPackageHandler

static SpilPackageHandler* sharedInstance;

+(SpilPackageHandler*)sharedInstance {
    static SpilPackageHandler *spilPackageHandler = nil;
    if (spilPackageHandler == nil)
    {
        // structure used to test whether the block has completed or not
        static dispatch_once_t p;
        dispatch_once(&p, ^{
            spilPackageHandler = [[SpilPackageHandler alloc] init];
        });
    }
    
    return spilPackageHandler;
}

-(NSArray*)getAllPackages{
    // get the current loaded packages
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *packages = [defaults objectForKey:@"com.spilgames.app.packages"];
    
    if ([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
        NSLog(@"[SpilPackageHandler] stored packages %@", packages);
    }
    
    // if empty write the default value
    if (packages == nil) {
        // get the default store packages from the json file.
        NSError *error = nil;
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"defaultStorePackages" ofType:@"json"];
        
        NSData *dataFromFile = [NSData dataWithContentsOfFile:filePath];
        if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
            NSLog(@"[SpilPackageHandler] dataFromFile %@",dataFromFile);
        }
        if(dataFromFile == NULL){
            if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
                NSLog(@"[SpilPackageHandler] Spil default store packages seems missing!");
            }
            return @[];
        }
        
        NSArray *data = [NSJSONSerialization JSONObjectWithData:dataFromFile options:kNilOptions error:&error];
        
        // check json data
        if (data != nil) {
            if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
                NSLog(@"[SpilPackageHandler] default package json data: %@",data);
            }
            
            // store it
            [defaults setObject:data forKey:@"com.spilgames.app.packages"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            packages = data;
            
        } else {
            if ([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
                NSLog(@"[SpilPackageHandler] json data is invalid");
            }
        }
    }
    
    return packages;
}

-(NSArray*)getAllPromotions {
    // get the current loaded promotions
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *promotions = [defaults objectForKey:@"com.spilgames.app.promotions"];
    
    if ([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
        NSLog(@"[SpilPackageHandler] stored promotions %@", promotions);
    }
    
    // if empty write the default value
    if (promotions == nil) {
        // get the default store promotions from the json file.
        NSError *error = nil;
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"defaultStorePromotions" ofType:@"json"];
        
        NSData *dataFromFile = [NSData dataWithContentsOfFile:filePath];
        if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
            NSLog(@"[SpilPackageHandler] dataFromFile %@",dataFromFile);
        }
        if(dataFromFile == NULL){
            if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) NSLog(@"[SpilPackageHandler] Spil default store promotions seems missing!");
            return @[];
        }
        
        NSArray *data = [NSJSONSerialization JSONObjectWithData:dataFromFile options:kNilOptions error:&error];
        
        // check json data
        if (data != nil) {
            if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) NSLog(@"[SpilPackageHandler] default promotion json data: %@",data);
            
            // store it
            [defaults setObject:data forKey:@"com.spilgames.app.promotions"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            promotions = data;
            
        } else {
            if ([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
                NSLog(@"[SpilPackageHandler] json data is invalid");
            }
        }
    }
    
    return promotions;
}

// gets a package for a key
-(NSDictionary*)getPackageByID:(NSString*)keyString {
    if(keyString == nil || [keyString isEqualToString:@""]) {
        return @{};
    }
    
    NSArray *packages = [[SpilPackageHandler sharedInstance] getAllPackages];
    for (NSDictionary* package in packages)
    {
        NSString *packageId = package[@"packageId"];
        if (packageId != nil && [packageId isEqualToString:keyString]) {
            return package;
        }
    }
    
    return @{};
}

// gets a promotion for a key
-(NSDictionary*)getPromotionByID:(NSString*)keyString {
    if(keyString == nil || [keyString isEqualToString:@""]) {
        return @{};
    }
    
    NSArray *promotions = [[SpilPackageHandler sharedInstance] getAllPromotions];
    for (NSDictionary* promotion in promotions)
    {
        NSString *promotionId = promotion[@"packageId"];
        if (promotionId != nil && [promotionId isEqualToString:keyString]) {
            return promotion;
        }
    }
    
    return @{};
}

-(void)requestPackages {
    [[SpilEventTracker sharedInstance] trackEvent:@"requestPackages"];
}

-(void)storePackages:(NSDictionary*)data {
    if(data == nil) {
        return;
    }
    
    // check for valid NSDictionary
    if ([[data allKeys] count] > 0) {
        if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
            NSLog(@"[SpilPackageHandler] Spil storing store package json data from server: %@", data);
        }
        
        NSDictionary *packages = data[@"packages"];
        NSDictionary *promotions = data[@"promotions"];
        
        // store packages & promotions
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (packages != nil) {
            [defaults setObject:packages forKey:@"com.spilgames.app.packages"];
        }
        if (promotions != nil) {
            [defaults setObject:promotions forKey:@"com.spilgames.app.promotions"];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // send a store packages loaded notification
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spilNotificationHandler" object:nil userInfo:@{@"event":@"packagesLoaded"}];
    }else{
        if([[SpilEventTracker sharedInstance] getAdvancedLoggingEnabled]) {
            NSLog(@"[SpilPackageHandler] json config dictionary seems empty %@ count %d", data, (int)[[data allKeys]count]);
        }
    }
}

@end
