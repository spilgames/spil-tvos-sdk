//
//  SpilAppStoreHandler.m
//  Spil
//
//  Created by Frank Slofstra on 03/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "SpilAppStoreHandler.h"
#import "AppStoreRequestData.h"
#import "SpilEventTracker.h"
#import "NSString+Extensions.h"

@interface SpilAppStoreHandler ()

@property (strong, nonatomic) NSMutableArray *appStoreQueue;

@end

@implementation SpilAppStoreHandler

@synthesize appStoreQueue;

static SpilAppStoreHandler* sharedInstance;

+ (SpilAppStoreHandler*)sharedInstance {
    static SpilAppStoreHandler *spilAppStoreHandler = nil;
    if (spilAppStoreHandler == nil)
    {
        // structure used to test whether the block has completed or not
        static dispatch_once_t p;
        dispatch_once(&p, ^{
            spilAppStoreHandler = [[SpilAppStoreHandler alloc] init];
        });
    }
    
    return spilAppStoreHandler;
}

-(id)init{
    self = [super init];
    
    self.appStoreQueue = [NSMutableArray array];
    
    return self;
}

-(void)requestAppStoreItemForEvent:(NSString*)name withParams:(NSDictionary*)params {
    if (params == nil || params[@"skuId"] == nil) {
        NSLog(@"[SpilAppStoreHandler] skuId not found in the event params data!");
        return;
    }
    
    NSLog(@"[SpilAppStoreHandler] Requesting product data for sku: %@", params[@"skuId"]);
    
    // Create the request
    NSString *productIdentifier = params[@"skuId"];
    NSSet *set = [NSSet setWithArray:@[productIdentifier]];
    SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers: set];
    request.delegate = self;
    
    // Load the receipt for the iap and add it as token to finalParams
    NSMutableDictionary *finalParams = [params mutableCopy];
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
    NSString *strReceipt = @"";
    if (receipt != nil) {
        strReceipt = [NSString base64StringFromData:receipt];
    }
    finalParams[@"token"] = strReceipt;
    
    // Store it
    AppStoreRequestData* appStoreRequestData = [[AppStoreRequestData alloc] initWithRequest:request withName:name withParams:finalParams withProductIdentifier:productIdentifier];
    [appStoreQueue addObject:appStoreRequestData];
    
    // Start it
    [request start];
}

#pragma mark SKProductsRequest delegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    if (response.products.count != 0) {
        for (SKProduct *product in response.products) {
            for (AppStoreRequestData *appStoreRequestData in self.appStoreQueue) {
                if ([product.productIdentifier isEqualToString:appStoreRequestData.productIdentifier]) {
                    NSString *eventName = appStoreRequestData.eventName;
                    NSMutableDictionary *params = appStoreRequestData.eventParams;
                    
                    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
                    [numberFormatter setLocale:product.priceLocale];
                    
                    NSString *localPrice = [NSString stringWithFormat:@"%.02f", [product.price floatValue]];
                    NSString *localCurrency = [product.priceLocale objectForKey:NSLocaleCurrencyCode];
                    
                    [params setValue:localPrice forKey:@"localPrice"];
                    [params setValue:localCurrency forKey:@"localCurrency"];
                    
                    NSLog(@"[SpilAppStoreHandler] Product %@ received from the app store, with localPrice: %@", appStoreRequestData.productIdentifier, localPrice);
                    
                    [[SpilEventTracker sharedInstance] trackEvent:eventName withParameters:params];
                    
                    [self.appStoreQueue removeObject:appStoreRequestData];
                    
                    return;
                }
            }
        }
    }
}

@end
