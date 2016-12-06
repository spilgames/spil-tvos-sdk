//
//  AppDelegate.m
//  MergedProjectTest
//
//  Created by Frank Slofstra on 14/04/16.
//  Copyright © 2016 Frank Slofstra. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"!!!didFinishLaunchingWithOptions");
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {

}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"!!!didReceiveRemoteNotification");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [Spil applicationDidEnterBackground:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [Spil start];
    [Spil setAdvancedLoggingEnabled:YES];
    [Spil applicationDidBecomeActive:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

@end
