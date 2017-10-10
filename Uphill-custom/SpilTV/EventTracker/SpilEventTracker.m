//
//  SpilEventTracker.m
//  trackerSample
//
//  Created by Martijn van der Gun on 5/28/15.
//  Copyright (c) 2015 Martijn van der Gun. All rights reserved.
//

#import "SpilEventTracker.h"
#import "SpilActionHandler.h"
#import "SpilAnalyticsHandler.h"
#import "SpilAppStoreHandler.h"
#import "NSString+Extensions.h"
#import "SpilUserHandler.h"
#import "Spil.h"
#import "Util.h"

@interface SpilEventTracker ()

@property (nonatomic) BOOL isUnity;
@property (strong, nonatomic) NSString *appId;
@property (nonatomic) BOOL advancedLoggingEnabled;
@property (atomic) BOOL hasNetworkConnection;
@property (atomic) BOOL isSendingEvent;
@property (strong, nonatomic) NSMutableDictionary *blocks;
@property (strong, nonatomic) NSString *lastSendingEventUID;
@property (strong, nonatomic) NSTimer *heartBeatTimer;
@property (strong, nonatomic) NSDate *ttoStartDate;
@property (strong, nonatomic) NSString *sessionId;
@property (strong, nonatomic) NSString *pluginName;
@property (strong, nonatomic) NSString *pluginVersion;
@property (strong, nonatomic) NSString *bundleIdOverride;
@property (strong, nonatomic) NSDate *sessionStartDate;

@end

@implementation SpilEventTracker

@synthesize hasNetworkConnection;
@synthesize isSendingEvent;
@synthesize pluginName;
@synthesize pluginVersion;
@synthesize bundleIdOverride;
@synthesize sessionStartDate;

#define MAX_CUE_ITEMS 1000
#define MAX_SECONDS_RESPONSE_TIME 5
#define HEARTBEAT_INTERVAL_SECONDS 60
#define INTERVAL_TIME_WHEN_NO_CONNECTION 10
#define SESSION_INTERVAL_SECONDS 900

// Old format
#define PRODUCTION_ENDPOINT @"https://apptracker.spilgames.com/apple_event"
#define STAGING_ENDPOINT @"http://api-stg.spilgames.com/apple_event"

// New format
#define USE_NEW_URL_FORMAT TRUE
#define NEW_PRODUCTION_ENDPOINT @"https://apptracker.spilgames.com/v1/native-events/event/ios"
#define NEW_STAGING_ENDPOINT @"http://api-stg.spilgames.com/v1/native-events/event/ios"

NSString *endPointPath = USE_NEW_URL_FORMAT ? NEW_PRODUCTION_ENDPOINT : PRODUCTION_ENDPOINT;

static SpilEventTracker* sharedInstance;

+ (SpilEventTracker*)sharedInstance {
    static SpilEventTracker *spilEventHandler = nil;
    if (spilEventHandler == nil)
    {
        // structure used to test whether the block has completed or not
        static dispatch_once_t p;
        dispatch_once(&p, ^{
            spilEventHandler = [[SpilEventTracker alloc] init];
        });
    }
    
    return spilEventHandler;
}

-(void)startWithAppId:(NSString*)appId{
    if([self getAdvancedLoggingEnabled]) {
        NSLog(@"[SpilEventTracker] eventCue %@",[self getEventCue]);
        NSLog(@"[SpilEventTracker] Spil: started eventracker with appId: %@",appId);
    }
    
    [self setAppId:appId];
    [[SpilUserHandler sharedInstance] syncSpilUserId];
    
    self.isSendingEvent = false;
    
    [self checkForNewInstallOrUpdate];
    
    // make sure we send a session start event, since the app won't send a did become active at start
    [self updateTTOSessionStart];
    
    [self startHeartBeat];
    
    // Listen to specific Unity Notification events
#ifdef UNITY
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(UnityListenerDidEnterBackground:)
                                                 name:@"UIApplicationDidEnterBackgroundNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(UnityListenerDidBecomeActive:)
                                                 name:@"UIApplicationDidBecomeActiveNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(UnityListenerDidFailRegisterDevice:)
                                                 name:@"kUnityDidFailToRegisterForRemoteNotificationsWithError"
                                               object:nil];
#endif
    
    [[SpilUserHandler sharedInstance] handleDuplicateUserId];
}

-(void)setCustomBundleId:(NSString*)bundleId {
    self.bundleIdOverride = bundleId;
}

#ifdef UNITY
-(void)UnityListenerDidEnterBackground:(NSNotification *)note{
    if(_advancedLoggingEnabled)NSLog(@"[SpilEventTracker] UnityListenerDidEnterBackground %@",note);
    [self applicationDidEnterBackground:nil];
}


-(void)UnityListenerDidBecomeActive:(NSNotification *)note{
    if(_advancedLoggingEnabled)NSLog(@"[SpilEventTracker] UnityListenerDidBecomeActive %@",note);
    [self applicationDidBecomeActive:nil];
}

-(void)UnityListenerDidRegisterDevice:(NSNotification *)note{
    if(_advancedLoggingEnabled)NSLog(@"[SpilEventTracker] Did register Device!! %@",note);
}

-(void)UnityListenerDidFailRegisterDevice:(NSNotification *)note{
    if(_advancedLoggingEnabled) NSLog(@"[SpilEventTracker] Did Fail register Device!! %@",note);
}

// NOTE: will not work when opening a push notifcation, issue is the SDK is loaded after the event is triggered
-(void)UnityListenerDidReceiveRemoteNotification:(NSNotification *)note{
    
    if(_advancedLoggingEnabled) NSLog(@"[SpilEventTracker] Did receive remote notification %@",note);
    /*
     UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"TEST"]
     message:[NSString stringWithFormat:@"Test"]
     delegate:self
     cancelButtonTitle:NSLocalizedString(@"OK",@"")
     otherButtonTitles:nil];
     [alert show];
     */
}

#endif

-(void)setAppId:(NSString*)appId {
    _appId = appId;
}

-(NSString*)getAppId {
    return _appId;
}

-(void)setPushKey:(NSString*)pushKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSString stringWithFormat:@"%@",pushKey] forKey:@"com.spilgames.pushkey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString*)getPushKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *pushkey = [defaults objectForKey:@"com.spilgames.pushkey"];
    if(pushkey == NULL )pushkey = @"-";
    return pushkey;
}

// Total time open in miliseconds
-(double)getTTO {
    // get the last saved TTO
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *last_tto_string = [defaults objectForKey:@"com.spilgames.tto"];
    if(last_tto_string == nil || last_tto_string == NULL || [last_tto_string isEqualToString:@""]){
        last_tto_string = @"0";
    }
    double last_tto = [last_tto_string doubleValue];
    
    // calculate the seconds difference from the session start time and now
    NSDate *tto_start = _ttoStartDate;
    NSDate *now = [NSDate new];
    NSTimeInterval secondsBetween = [now timeIntervalSinceDate:tto_start];
    double seconds = secondsBetween;
    if(isnan(seconds) || seconds < 0) {
        seconds = 0;
    }
    
    // session seconds plus the saved time
    return last_tto + seconds;
}

-(double)getTTOinMS {
    return [self getTTO] * 1000;
}

-(void)updateTTOSessionStart{
    _ttoStartDate = [NSDate new];
    
    if(_advancedLoggingEnabled) {
        NSLog(@"[SpilEventTracker] updateTTOSessionStart %@", _ttoStartDate);
    }
}

-(void)saveTTO{
    // save the current tto for the next session
    double currentTTO = [self getTTO];
    
    if(_advancedLoggingEnabled) {
        NSLog(@"[SpilEventTracker] saveTTO %lf", currentTTO);
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSString stringWithFormat:@"%lf",currentTTO] forKey:@"com.spilgames.tto"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // set the last tto start date as a formality
    [self updateTTOSessionStart];
}

-(BOOL)getAdvancedLoggingEnabled {
    if ([self hasAdvancedLogginOverride]) {
        return true;
    }
    return _advancedLoggingEnabled;
}

-(void)setAdvancedLogging:(BOOL)advancedLoggingEnabled {
    _advancedLoggingEnabled = advancedLoggingEnabled;
}

-(BOOL)debugModeEnabled {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"embedded.mobileprovision" ofType:nil];
    BOOL mobileProvisionExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"spil_debugmode"] == YES // Settings menu
            || mobileProvisionExists; // AdHoc | Dev provision profile
}

-(BOOL)hasAdvancedLogginOverride {
    NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:@"spil_password"];
    return [password isEqualToString:@"sp1l"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"spil_advancedlogging"] == YES;
}

-(void)setPluginInformation:(NSString*)pluginNameParam pluginVersion:(NSString*)pluginVersionParam {
    self.pluginName = pluginNameParam;
    self.pluginVersion = pluginVersionParam;
}

-(void)staging:(Boolean)stagingEnabled {
    NSLog(@"[SpilEventTracker] using staging server: %@", stagingEnabled ? @"yes" : @"no");
    
    if (USE_NEW_URL_FORMAT) {
        endPointPath = stagingEnabled ? NEW_STAGING_ENDPOINT : NEW_PRODUCTION_ENDPOINT;
    } else {
        endPointPath = stagingEnabled ? STAGING_ENDPOINT : PRODUCTION_ENDPOINT;
    }
}

-(void)setLastSendingEventUID:(NSString*)lastSendingEventUID{
    _lastSendingEventUID = lastSendingEventUID;
}

-(NSString*)getLastSendingEventUID{
    return _lastSendingEventUID;
}

-(void)setBlocks:(NSMutableDictionary*)blocks{
    _blocks = blocks;
}

-(NSMutableDictionary*)getBlocks{
    return _blocks;
}

-(BOOL)getIsSendingEvent{
    return self.isSendingEvent;
}

-(NSString*)getUID{
    return [[NSUUID UUID] UUIDString]; // generates a unique ID
}

-(void) trackEvent:(NSString*)name{
    
    [self trackEvent:name onResponse:nil];
}

-(void) trackEvent:(NSString*)name withParameters:(NSDictionary *)params{
    [self trackEvent:name withParameters:params onResponse:nil];
}

-(void) trackEvent:(NSString*)name onResponse:(void (^)(id response))block{
    [self trackEvent:name withParameters:nil onResponse:block];
}

-(void) trackEvent:(NSString*)name withParameters:(NSDictionary *)params onResponse:(void (^)(id response))block{
    dispatch_async(dispatch_get_main_queue(), ^ {
        //NSLog(@"[SpilEventTracker] trackEvent: %@ withParams: %@", name, params);
        
        if (params != nil) {
            if ([name isEqualToString:@"iapPurchased"]) {
                if (params[@"localPrice"] == nil) {
                    [[SpilAppStoreHandler sharedInstance] requestAppStoreItemForEvent:name withParams:params];
                    return;
                }
            }
        }
        
        NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
        [data setObject:name forKey:@"eventName"];
        [data setObject:[self timeStamp] forKey:@"userTimeStamp"];
        [data setObject:[self getUID] forKey:@"eventUID"];
        [data setObject:[NSString stringWithFormat:@"%.lf", [self getTTOinMS]] forKey:@"tto"];
        [data setObject:[self getSessionId] forKey:@"sessionId"];
        NSString *duration = [self getSessionDuration];
        [data setObject:duration forKey:@"sessionDuration"];
        if(params == nil) {
            [data setObject:@"" forKey:@"eventData"];
        } else {
            [data setObject:params forKey:@"eventData"];
        }
        
        [self addEventToCue:data];
        
        if (block != nil) {
            [self registerBlock:block forUID:data[@"eventUID"]];
        }
    });
}

- (NSString *) getSessionDuration {
    NSDate *currentDate = [NSDate new];
    NSTimeInterval secondsBetween = [currentDate timeIntervalSinceDate:sessionStartDate];
    return [NSString stringWithFormat:@"%.0f", (secondsBetween * 1000)];
}

- (NSString *) timeStamp {
    return [NSString stringWithFormat:@"%.0f",([[NSDate date] timeIntervalSince1970]*1000)];
}


-(void)applicationWillResignActive:(UIApplication *)application{
    if(_advancedLoggingEnabled) {
        NSLog(@"[SpilEventTracker] SPIL applicationWillResignActive: %@",application);
    }
}

-(void)applicationDidEnterBackground:(UIApplication *)application{
    if(_advancedLoggingEnabled) {
        NSLog(@"[SpilEventTracker] SPIL applicationDidEnterBackground: %@",application);
    }
    
    [self saveTTO];
    
    [self trackEvent:@"sessionStop"];
    [self stopHeartBeat];
    
}

-(void)applicationWillEnterForeground:(UIApplication *)application{
    if(_advancedLoggingEnabled) {
        NSLog(@"[SpilEventTracker] SPIL applicationWillEnterForeground: %@",application);
    }
}

-(void)applicationDidBecomeActive:(UIApplication *)application{
    if(_advancedLoggingEnabled) {
        NSLog(@"[SpilEventTracker] SPIL applicationDidBecomeActive: %@",application);
    }
    
    [self updateTTOSessionStart];
    
    [self trackEvent:@"sessionStart"];
    [self startHeartBeat];
    
}

-(void)applicationWillTerminate:(UIApplication *)application{
    if(_advancedLoggingEnabled) {
        NSLog(@"[SpilEventTracker] SPIL applicationWillTerminate: %@",application);
    }
}

-(NSMutableArray*)getEventCue{
    if(_advancedLoggingEnabled) {
        NSLog(@"[SpilEventTracker] get Event cue");
    }
    
    //NSError *error;
    //NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    //NSString *path = [documentsDirectory stringByAppendingPathComponent:@"events.plist"];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"events.plist"];
    
    if(_advancedLoggingEnabled)NSLog(@"[SpilEventTracker] path %@", path);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // create if not exists
    if (![fileManager fileExistsAtPath: path])
    {
        if(_advancedLoggingEnabled) {
            NSLog(@"[SpilEventTracker] CREATE PLIST FILE");
        }
        
        if(_advancedLoggingEnabled) {
            NSLog(@"[SpilEventTracker] path %@",path);
        }
        
        //NSString *bundle = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"events.plist"];
        //[fileManager copyItemAtPath:bundle toPath: path error:&error];
        
        // write empty events key
        //NSMutableArray *data = [[NSMutableArray alloc] initWithContentsOfFile: path];
        
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
        [dictionary setObject:[[NSMutableArray alloc]init] forKey:@"events"];
        
        //[data addObject:[[NSMutableDictionary alloc]init] ]
        
        //[data setObject:[[NSMutableArray alloc]init] forKey:@"events"];
        [dictionary writeToFile: path atomically:YES];
        
        /*NSMutableDictionary *data= [[NSMutableDictionary alloc] initWithContentsOfFile: path];
        if(_advancedLoggingEnabled) {
            NSLog(@"[SpilEventTracker] data %@",data);
        }*/
    }
    
    NSMutableDictionary *savedStock = [[NSMutableDictionary alloc] initWithContentsOfFile: path];
    
    // load from savedStock
    NSMutableArray *eventCue;
    eventCue = [savedStock objectForKey:@"events"];
    
    if(eventCue == NULL)return [[NSMutableArray alloc]init];
    
    return eventCue;
}

-(void)addEventToCue:(NSDictionary*)eventData {
    NSMutableArray *eventCue = [self getEventCue];
    int cueCount = (int)[eventCue count];
    
    // always only allow one heart beat event in the cue, replace any existing with the new one.
    for(int i = 0; i<cueCount; i++){
        if([eventCue objectAtIndex:i] && [eventCue objectAtIndex:i][@"eventName"] != nil){
            if([[eventCue objectAtIndex:i][@"eventName"] isEqualToString:@"heartBeat"]){
                // remove event
                [eventCue removeObjectAtIndex:i];
                break;
            }
        }
    }
    
    // add the new event to the cue
    [eventCue addObject:eventData];
    
    // remove events that exceed the cue limit
    cueCount = (int)[eventCue count];
    if(cueCount > MAX_CUE_ITEMS) {
        NSRange r;
        r.location = 0;
        r.length = cueCount - MAX_CUE_ITEMS;
        [eventCue removeObjectsInRange:r];
    }
    
    [self saveEventCue:eventCue sendEventCue:true];
}

-(void)saveEventCue:(NSMutableArray*)eventCue sendEventCue:(BOOL)send{
    //NSError *error;
    //NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    //NSString *path = [documentsDirectory stringByAppendingPathComponent:@"events.plist"];
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"events.plist"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // create if not exists
    if (![fileManager fileExistsAtPath: path])
    {
        if(_advancedLoggingEnabled) {
            NSLog(@"[SpilEventTracker] Path not existing, create PLIST %@",path);
        }
    }
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile: path];
    if (data == nil) {
        data = [NSMutableDictionary dictionary];
    }
    //if(_advancedLoggingEnabled)NSLog(@"[SpilEventTracker] save event que data: %@", data);
    [data setObject:[eventCue copy] forKey:@"events"];
    [data writeToFile: path atomically:YES];
    
    if(send)
        [self sendEventCue];
}

-(void)sendEventData:(NSDictionary*)data {
    //NSLog(@"[SpilEventTracker] data:%@",data);
    
    // Make sure we only have one running connection at the time
    if([self getIsSendingEvent] == true) {
        return;
    }
    self.isSendingEvent = true;
    
    // Keep track of the last event UID in progress
    if(_advancedLoggingEnabled) {
        NSLog(@"[SpilEventTracker] set setLastSendingEventUID: %@ eventname: %@",data[@"eventUID"], data[@"eventName"]);
    }
    [self setLastSendingEventUID:data[@"eventUID"]];
    
    
    // --- Build the dataToSend data including all the default request data ---
    NSMutableDictionary *dataToSend = [self userData];
    
    // Copy over the eventData part to the dataToSend
    NSMutableDictionary *customData = [NSMutableDictionary dictionary];
    if([data[@"eventData"] isKindOfClass:[NSDictionary class]]){
        for (NSString* key in data[@"eventData"]) {
            id value = [data[@"eventData"] objectForKey:key];
            [customData setObject:value forKey:key];
        }
    }
    
    // Copy over the tto field to the new dataToSend
    [dataToSend setObject:data[@"tto"] forKey:@"tto"];
    
    // Copy over the sessionId field to the new dataToSend
    if (data[@"sessionId"] != nil) {
        [dataToSend setObject:data[@"sessionId"] forKey:@"sessionId"];
    } else {
        // For old queued events not having a sessionId, use the latest session id
        [dataToSend setObject:[self getSessionId] forKey:@"sessionId"];
    }
    
    // Copy over the sessionDuration field to the new dataToSend
    if (data[@"sessionDuration"] != nil) {
        [dataToSend setObject:data[@"sessionDuration"] forKey:@"sessionDuration"];
    }
    
    // Get the timestamp from the original data object
    NSString *timestamp = [NSString stringWithFormat:@"%.0f", [data[@"userTimeStamp"] doubleValue]];
    
    // Determine if this is a queued event, based on the timestamp of the event and the current timestamp
    BOOL queued = false;
    if([self secondsAgo:data[@"userTimeStamp"]] > 10000) {
        queued = true; // ms
    }
    
    // Use the event name from the original data object
    NSString *eventName = [NSString stringWithFormat:@"%@",data[@"eventName"]];
    eventName = [eventName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    
    // --- Convert the data and custom data to JSON ---
    NSString *jsonDataString = [self jsonString:dataToSend withPrettyPrint:0];
    NSString *jsonCustomDataString = [self jsonString:customData withPrettyPrint:0];
    
    // --- Build the url string ---
    NSString *customEndPointPath = endPointPath;
    if (USE_NEW_URL_FORMAT) {
        
        NSString *pBundleId = [Util urlEncode:[self getBundleId]];
        NSString *pEventName = [Util urlEncode:eventName];
        customEndPointPath = [NSString stringWithFormat:@"%@/%@/%@", customEndPointPath, pBundleId, pEventName];
    }
    
    // Building the debug mode string part
    NSString *debugModePart = @"";
    /*if ([self debugModeEnabled]) {
        debugModePart = @"&debugMode=true";
    }*/
    
    // Building the total url string
    NSString *pEventName = [Util urlEncode:eventName];
    NSString *pDataJson = [Util urlEncode:jsonDataString];
    NSString *pCustomJson = [Util urlEncode:jsonCustomDataString];
    NSString *stringPackage = [NSString stringWithFormat:@"name=%@&ts=%@&data=%@&customData=%@%@&queued=%d", pEventName, timestamp, pDataJson, pCustomJson, debugModePart, queued];
    NSString *pStringPackage = [Util urlDecode:stringPackage];
    NSLog(@"[SPIL] >>> Starting request (%@, baseurl: %@): %@", eventName, customEndPointPath, pStringPackage);

    // --- Create the url request and add the post data to it ---
    NSURL *url = [NSURL URLWithString:customEndPointPath];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:MAX_SECONDS_RESPONSE_TIME];
    [request setHTTPMethod:@"POST"];
    NSData *requestData = [NSData dataWithBytes:[stringPackage UTF8String] length:[stringPackage length]];
    [request setValue:[NSString stringWithFormat:@"%ld", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    
    // --- Send the request and handle the response ---
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
         dispatch_async(dispatch_get_main_queue(), ^ {
             if ([data length] > 0 && error == nil){
                 self.hasNetworkConnection = true;
                 
                 NSString *receivedString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                 
                 // Logging events will return an empty body, we don't need to parse the config then..
                 if(![receivedString isEqualToString:@""] && ![receivedString isEqualToString:@"\n"]){
                     NSLog(@"[SPIL] <<< Request finished (%@): %@", eventName, receivedString);
                     
                     NSData *data = [receivedString dataUsingEncoding:NSUTF8StringEncoding];
                     if(data != NULL){
                         NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                         if (JSON != nil) {
                             [self parseReply:JSON];
                         
                             // success, trigger the callback
                             [self executeBlockWithUID:_lastSendingEventUID withResponse:JSON];
                         } else {
                             NSDictionary *responseData = @{@"error":@"request failed"};
                             [self executeBlockWithUID:_lastSendingEventUID withResponse:responseData];
                         }
                     } else {
                         // failed, trigger the callback
                         NSDictionary *responseData = @{@"error":@"empty data"};
                         [self executeBlockWithUID:_lastSendingEventUID withResponse:responseData];
                     }
                 } else {
                     // failed, trigger the callback
                     NSDictionary *responseData = @{@"error":@"empty response"};
                     [self executeBlockWithUID:_lastSendingEventUID withResponse:responseData];
                 }
                 
                 // Request handled, remove the request from the queue
                 NSString *UID = [self getLastSendingEventUID];
                 [self removeEventByUID:UID];
             }
             else if ([data length] == 0 && error == nil){
                 NSLog(@"[SpilEventTracker] !!! Request returned empty response");
                 
                 self.hasNetworkConnection = false; // we handle this the same as no conenction, as there would be an issue with the server
                 
                 NSDictionary *responseData = @{@"error":@"empty response"};
                 [self executeBlockWithUID:_lastSendingEventUID withResponse:responseData];
                 
                 // Handle as a succeeded response, remove the request from the queue
                 NSString *UID = [self getLastSendingEventUID];
                 [self removeEventByUID:UID];
             }
             else if (error != nil && error.code == NSURLErrorTimedOut) {
                 NSLog(@"[SpilEventTracker] !!! Request timedOut");
                 
                 self.hasNetworkConnection = false; // we handle this the same as no conenction, as there would be an issue with the server
                 
                 NSDictionary *responseData = @{@"error":@"server timout"};
                 [self executeBlockWithUID:_lastSendingEventUID withResponse:responseData];
             }
             else if (error != nil &&
                      ((error.code >= 502 && error.code <= 504) || (error.code < 0))) {
                 NSLog(@"[SpilEventTracker] !!! Request failed: %@", error);
                 self.hasNetworkConnection = false; // we handle this the same as no conenction, as there would be an issue with the server
                 
                 NSDictionary *responseData = @{@"error":@"no connection"};
                 [self executeBlockWithUID:_lastSendingEventUID withResponse:responseData];
             }
             
             if(self.hasNetworkConnection) {
                 // connection is good so send next event in the cue
                 self.isSendingEvent = false;
                 [self sendEventCue]; // continue sending the other events..
             } else {
                 NSLog(@"[SpilEventTracker] No connection, retry in 10 seconds");
                 // we've don't seem to have a stable connection, retry in X seconds
                 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, INTERVAL_TIME_WHEN_NO_CONNECTION * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                     self.isSendingEvent = false;
                     [self sendEventCue]; // continue sending the other events..
                 });
             }
         });
     }];
}

-(NSString*)jsonString:(id)jsonString withPrettyPrint:(BOOL) prettyPrint {
    NSString* result = [JsonUtil convertObjectToJson:jsonString];
    if (result == nil) {
        result = @"[]";
    }
    return result;
}

-(NSMutableDictionary*)userData{
    NSMutableDictionary *userData = [[NSMutableDictionary  alloc] init];
    [userData setObject:[self getAppId] forKey:@"appId"];
    [userData setObject:SDK_VERSION forKey:@"apiVersion"];
    [userData setObject:[[SpilUserHandler sharedInstance] getUserId] forKey:@"uid"];
    [userData setObject:[self getLanguage] forKey:@"locale"];
    [userData setObject:[self getOsVersion] forKey:@"osVersion"];
    [userData setObject:[self getBundleId] forKey:@"bundleId"];
    [userData setObject:[self getAppVersion] forKey:@"appVersion"];
    [userData setObject:[self getDeviceModel] forKey:@"deviceModel"];
    [userData setObject:[self getTimezoneOffset] forKey:@"timezoneOffset"];
    [userData setObject:[self getPushKey] forKey:@"pushKey"];
    [userData setObject:[self getSessionId] forKey:@"sessionId"];
    [userData setObject:@"ios" forKey:@"os"];
    
    // Add analytics identifiers for adjust
    if ([[SpilAnalyticsHandler sharedInstance] isUsingAdjust]) {
        [userData setObject:[[SpilAnalyticsHandler sharedInstance] getIDFV] forKey:@"idfv"];
        if ([[SpilAnalyticsHandler sharedInstance] getIDFA] != nil) {
            [userData setObject:[[SpilAnalyticsHandler sharedInstance] getIDFA] forKey:@"idfa"];
        }
    }
    
    // Add plugin information
    if (self.pluginName != nil && self.pluginVersion != nil) {
        [userData setObject:self.pluginName forKey:@"pluginName"];
        [userData setObject:self.pluginVersion forKey:@"pluginVersion"];
    }
    
    NSDictionary *externalUserData = [[SpilUserHandler sharedInstance] getExternalUserRequestData];
    if (externalUserData != nil) {
        [userData setObject:externalUserData forKey:@"externalUserId"];
    }
    
    return userData;
}

-(NSString*)getLanguage{
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    return language;
}

-(NSString*)getOsVersion{
    NSString *osVersion = [UIDevice currentDevice].systemVersion;
    return osVersion;
}

-(NSString*)getBundleId{
    if (self.bundleIdOverride != nil) {
        return self.bundleIdOverride;
    } else {
        return [[NSBundle mainBundle] bundleIdentifier];
    }
}

-(NSString*)getAppVersion{
    NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return appBuildString;
}

-(NSString*)getDeviceModel{
    NSString *deviceModel = [UIDevice currentDevice].model;
    return deviceModel;
}

-(NSString*)getTimezoneOffset{
    NSString *offset = [NSString stringWithFormat:@"%d",(int)([[NSTimeZone localTimeZone] secondsFromGMT]/60)];
    return offset;
}

-(NSString*)getSessionId {
    // check if the sessionid is in the history
    if(_sessionId == nil){
        // check the old stored one or generate one
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *storedSessionId = [defaults objectForKey:@"com.spilgames.sessionid"];
        
        if(storedSessionId == nil || [storedSessionId isEqualToString:@""]) {
            // generate new
            _sessionId = [self generateSessionId];
            NSLog(@"[SpilEventTracker] session id was nil, generated new: %@",_sessionId);
            
        }else {
            _sessionId = storedSessionId;
            NSLog(@"[SpilEventTracker] session id was stored: %@",_sessionId);
        }
        
        // Init the session start date
        self.sessionStartDate = [NSDate new];
    }
    
    // get the session end date.
    NSDate *sessionEndDate = [self getSessionEndDate];
    
    // generate new session id, if session end date not exists
    if(sessionEndDate == nil){
        _sessionId = [self generateSessionId];
        self.sessionStartDate = [NSDate new];
        NSLog(@"[SpilEventTracker] session id end date was not set, generated new sessionid: %@",_sessionId);
    }
    
    // check if difference is bigger then 15 minutes
    NSTimeInterval secondsBetween = [[NSDate new] timeIntervalSinceDate:sessionEndDate];
    if(secondsBetween >= SESSION_INTERVAL_SECONDS){
        // invalidate session
        _sessionId = [self generateSessionId];
        self.sessionStartDate = [NSDate new];
        NSLog(@"[SpilEventTracker] sessionid time in between passed %d, generated new sessionid: %@",(int)secondsBetween, _sessionId);
    }else{
        // update the session date, re-use current session id.
        [self updateSessionDate];
    }
    
    //NSLog(@"[SpilEventTracker] session id: %@",_sessionId);
    
    return _sessionId;
    
}

-(NSString*)generateSessionId{
    // generate a new unique sessionId
    NSString *uniqueSessionId = [[NSUUID UUID] UUIDString];
    
    // update the sessionId
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSString stringWithFormat:@"%@",uniqueSessionId] forKey:@"com.spilgames.sessionid"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // save the last the date
    [self updateSessionDate];
    
    return uniqueSessionId;
}

// keep track of the date the app was last active
-(void)updateSessionDate{
    NSDate *currentDate = [NSDate new];
    
    //NSLog(@"[SpilEventTracker] update session date: %@",currentDate);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:currentDate forKey:@"com.spilgames.sessionEndDate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

-(NSDate*)getSessionEndDate{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *sessionEndDate = [defaults objectForKey:@"com.spilgames.sessionEndDate"];
    
    return sessionEndDate;
}

-(void)parseReply:(NSDictionary*)data{
    // intercept responses for possible actions
    [self processResponse:data];
}

-(void)processResponse:(NSDictionary*)data{
    NSString *callbackUID = [NSString stringWithString:_lastSendingEventUID]; // copy
    [SpilActionHandler handleAction:data withCallBackUID:callbackUID];
}

-(void)sendEventCue{
    //if(_advancedLoggingEnabled)NSLog(@"[SpilEventTracker] in sendEventCue with state: %d",[self getIsSendingEvent]);
    
    // already sending -> cancel new connection
    if([self getIsSendingEvent] == true){
        //if(_advancedLoggingEnabled)NSLog(@"[SpilEventTracker] event already sending");
        return;
    }
    
    // get the first event from the cue
    NSMutableDictionary *event = [self getFirstEventFromCue];
    if(!event) {
        return;
    }
    
    // send the event
    [self sendEventData:event];
}

-(void)removeEventByUID:(NSString*)UID{
    if(UID == nil || UID == NULL) return;
    
    // get the event cue
    NSMutableArray *eventCue = [self getEventCue];
    int cueCount = (int)[eventCue count];
    
    // search the event UID and remove
    for(int i = 0; i<cueCount; i++){
        if([eventCue objectAtIndex:i] && [eventCue objectAtIndex:i][@"eventName"] != nil){
            if([[eventCue objectAtIndex:i][@"eventUID"] isEqualToString:UID]){
                // remove event
                [eventCue removeObjectAtIndex:i];
                break;
            }
        }
    }
    
    // save the new cue
    [self saveEventCue:eventCue sendEventCue:true];
}

-(NSMutableDictionary*)getFirstEventFromCue{
    NSMutableArray *eventCue = [self getEventCue];
    if([eventCue count]>0)return [eventCue[0] mutableCopy];
    return nil;
}

-(void)removeFirstEventFromCue{
    NSMutableArray *eventCue = [self getEventCue];
    if([eventCue count] >0){
        [eventCue removeObjectAtIndex:0];
        [self saveEventCue:eventCue sendEventCue:false];
    }
}

-(int)secondsAgo:(NSString*)eventTimestamp {
    NSString *now = [self timeStamp];
    
    double diff = [now doubleValue] - [eventTimestamp doubleValue];
    int diffInSeconds = (int)ceilf((diff));
    
    if(_advancedLoggingEnabled) {
        NSLog(@"[SpilEventTracker] now: %f event: %f diff %f  seconds %d", [now doubleValue], [eventTimestamp doubleValue],diff, diffInSeconds);
    }
    
    return diffInSeconds;
}

-(void)registerBlock:(id)blockToSave forUID:(NSString*)UID{
    if(_advancedLoggingEnabled) {
        NSLog(@"[SpilEventTracker] register Block for event: %@",UID);
    }
    
    // just create an empty dictionary if not exists
    if([self getBlocks] == nil)
        [self setBlocks:[[NSMutableDictionary alloc] init]];
    
    
    NSMutableDictionary *blocks = [self getBlocks];
    
    // create (or overwrite current)
    [blocks setObject:blockToSave forKey:UID];
    
    // save new blocks
    [self setBlocks:blocks];
    
    //if(_advancedLoggingEnabled)NSLog(@"[SpilEventTracker] new blocks ARRAY: %@",[self getBlocks]);
}

-(void)removeBlockForUID:(NSString*)UID{
    // just create an empty dictionary if not exists
    if([self getBlocks] == nil) {
        [self setBlocks:[[NSMutableDictionary alloc] init]];
    }
    
    NSMutableDictionary *blocks = [self getBlocks];
    if(blocks) {
        // remove block for UID
        [blocks removeObjectForKey:UID];
        
        // save the new blocks array
        [self setBlocks:blocks];
    }
}

-(void)executeBlockWithUID:(NSString*)UID withResponse:(id)response {
    //NSLog(@"[SpilEventTracker] executeBlockWithUID %@", UID);
    
    // just create an empty dictionary if not exists
    if([self getBlocks] == nil)
        [self setBlocks:[[NSMutableDictionary alloc] init]];
    
    
    //if(_advancedLoggingEnabled)NSLog(@"[SpilEventTracker] blocks ARRAY: %@",[self getBlocks]);
    
    // debugging
    bool alreadyExecuted = false;
    if([[self getBlocks]  objectForKey:UID] == nil) {
        alreadyExecuted = true;
    }
    if(_advancedLoggingEnabled)NSLog(@"[SpilEventTracker] executeBlockWithUID %@ ignore = %d", UID, alreadyExecuted);
    
    //if(_advancedLoggingEnabled)NSLog(@"[SpilEventTracker] BLOCK about to execute %@", [[self getBlocks] objectForKey:UID]);
    
    //NSLog(@"[SpilEventTracker] lookup block attached to event %@", UID);
    
    // lookup block attached to event
    void(^myAwesomeBlock)() = [[self getBlocks] objectForKey:UID];
    
    // remove block in array
    [self removeBlockForUID:UID];
    
    // excute block from memory
    if(myAwesomeBlock){
        //NSLog(@"[SpilEventTracker] excute block from memory",UID);
        myAwesomeBlock(response);
    }
}

-(void)stopHeartBeat{
    [_heartBeatTimer invalidate];
    _heartBeatTimer = nil;
}

-(void)startHeartBeat{
    
    if(_advancedLoggingEnabled)NSLog(@"[SpilEventTracker] start Heartbeat %@",_heartBeatTimer);
    if(_heartBeatTimer == nil || _heartBeatTimer == NULL){
        _heartBeatTimer = [NSTimer scheduledTimerWithTimeInterval:HEARTBEAT_INTERVAL_SECONDS
                                                           target:self
                                                         selector:@selector(sendHeartBeat:)
                                                         userInfo:nil
                                                          repeats:YES];
    }
}

-(void)sendHeartBeat:(id)sender{
    
    [self trackEvent:@"heartBeat"];
}

-(void)checkForNewInstallOrUpdate{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *installed = [defaults objectForKey:@"com.spilgames.app.installed"];
    
    if(installed != nil && [installed isEqualToString:@"1"]){
        
        // check for updates
        NSString *version = [defaults objectForKey:@"com.spilgames.app.version"];
        NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        
        if(version != nil && ![version isEqualToString:appVersionString] ){
            
            // let the server know it was a new update
            [self trackEvent:@"update"];
        }
        
        // always save the latest
        [defaults setObject:appVersionString forKey:@"com.spilgames.app.version"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }else{
        
        [defaults setObject:@"1" forKey:@"com.spilgames.app.installed"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // let the server know it was a fresh install
        [self trackEvent:@"install"];
    }
}

-(void)isUnity:(BOOL)unityEnabled{
    [self setUnity:unityEnabled];
}

-(void)setUnity:(BOOL)unity{
    _isUnity = unity;
}

-(BOOL)isUnity{
    return _isUnity;
}

@end
