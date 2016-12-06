//
//  TestSandboxVC.m
//  SpilSDKTestProject
//
//  Created by Frank Slofstra on 03/08/16.
//  Copyright © 2016 Frank Slofstra. All rights reserved.
//

#import "TestSandboxVC.h"
#import "SpilTV/Spil.h"
#import "SpilTV/SpilActionHandler.h"

@interface TestSandboxVC ()

@end

@implementation TestSandboxVC

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)buttonAPressed:(id)sender {
    for (int i=0;i<100;i++) {
        NSString *eventName = [NSString stringWithFormat:@"TestEvent%d", i];
        [Spil trackEvent:eventName];
        //[self createEventInNewThread:eventName];
    }
}

- (IBAction)testAutomatedEvents:(id)sender {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:@"http://files.cdn.spilcloud.com/10/1472028212_demo/index.html" forKey:@"url"];
    [data setObject:[NSNumber numberWithInteger:1472601600] forKey:@"to"];
    [data setObject:@"https://play.google.com/store/apps/details?id=com.spilgames.a10.peacekeeper" forKey:@"promotedGameUrl"];
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:@"" forKey:@"name"];
    [dictionary setObject:@"overlay" forKey:@"type"];
    [dictionary setObject:@"" forKey:@"message"];
    [dictionary setObject:@"show" forKey:@"action"];
    [dictionary setObject:data forKey:@"data"];
    
    [SpilActionHandler handleAction:dictionary withCallBackUID:@"test"];
}

- (IBAction)testDFPBanner:(id)sender {
    //[Spil showBanner];
}

- (void)createEventInNewThread:(NSString*)eventName {
    NSLog(@"Creating thread: %@", eventName);
    [NSThread detachNewThreadSelector:@selector(sendEvent:) toTarget:[TestSandboxVC class] withObject:eventName];
}

+(void)sendEvent:(NSString*)eventName {
    NSLog(@"Sending event: %@", eventName);
    [Spil trackEvent:eventName];
}

@end
