//
//  SpilEventTracker.h
//  trackerSample
//
//  Created by Martijn van der Gun on 5/28/15.
//  Copyright (c) 2015 Martijn van der Gun. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SpilEventTracker : NSObject

+(SpilEventTracker*)sharedInstance;

-(void)startWithAppId:(NSString*)apiKey;

-(void)setCustomBundleId:(NSString*)bundleId;
-(NSString*)getBundleId;

-(void)setAdvancedLogging:(BOOL)advancedLoggingEnabled;
-(BOOL)getAdvancedLoggingEnabled;
-(void)setPluginInformation:(NSString*)pluginNameParam pluginVersion:(NSString*)pluginVersionParam;
-(void)staging:(Boolean)stagingEnabled;
-(BOOL)debugModeEnabled;

-(void) trackEvent:(NSString*)name;
-(void) trackEvent:(NSString*)name withParameters:(NSDictionary *)params;

-(void) trackEvent:(NSString*)name onResponse:(void (^)(id response))block;
-(void) trackEvent:(NSString*)name withParameters:(NSDictionary *)params onResponse:(void (^)(id response))block;

-(void)applicationWillResignActive:(UIApplication *)application;
-(void)applicationDidEnterBackground:(UIApplication *)application; // important
-(void)applicationWillEnterForeground:(UIApplication *)application;
-(void)applicationDidBecomeActive:(UIApplication *)application;  // important
-(void)applicationWillTerminate:(UIApplication *)application;

-(void)registerBlock:(id)blockToSave forUID:(NSString*)UID;
-(void)executeBlockWithUID:(NSString*)UID withResponse:(id)response;

#ifdef UNITY
-(void)UnityListenerDidEnterBackground:(NSNotification *)note;
-(void)UnityListenerDidBecomeActive:(NSNotification *)note;
-(void)UnityListenerDidRegisterDevice:(NSNotification *)note;
-(void)UnityListenerDidFailRegisterDevice:(NSNotification *)note;
-(void)UnityListenerDidReceiveRemoteNotification:(NSNotification *)note;
#endif

-(void)setPushKey:(NSString*)pushKey;

-(void)isUnity:(BOOL)unityEnabled;
-(BOOL)isUnity;

@end
