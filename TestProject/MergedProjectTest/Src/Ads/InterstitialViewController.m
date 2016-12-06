#import "AppDelegate.h"
#import "InterstitialViewController.h"

@interface InterstitialViewController()

@property (nonatomic, strong) NSString *adProvider;

@end

@implementation InterstitialViewController

@synthesize adProvider;

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [Spil sharedInstance].delegate = self;
    
    [self updateProviderButtons];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self updateProviderButtons];
}

-(IBAction)onFyberRequestButtonPressed:(id)sender {
    //self.chartboostRequestButton.backgroundColor = [UIColor lightGrayColor];
    //self.googleRequestButton.backgroundColor = [UIColor lightGrayColor];
    //self.fyberRequestButton.backgroundColor = [UIColor greenColor];
    
    //[self.playButton setEnabled:NO];
    self.adProvider = @"fyber";
    [Spil devRequestAd:self.adProvider withAdType:@"interstitial" withParentalGate:NO];
}

-(IBAction)onChartboostRequestButtonPressed:(id)sender {
    //self.fyberRequestButton.backgroundColor = [UIColor lightGrayColor];
    //self.googleRequestButton.backgroundColor = [UIColor lightGrayColor];
    //self.chartboostRequestButton.backgroundColor = [UIColor greenColor];
    
    //[self.playButton setEnabled:NO];
    self.adProvider = @"chartboost";
    [Spil devRequestAd:self.adProvider withAdType:@"interstitial" withParentalGate:NO]; // TODO parental gate
}

-(IBAction)onGoogleRequestButtonPressed:(id)sender {
    //self.fyberRequestButton.backgroundColor = [UIColor lightGrayColor];
    //self.chartboostRequestButton.backgroundColor = [UIColor lightGrayColor];
    //self.googleRequestButton.backgroundColor = [UIColor greenColor];
    
    //[self.playButton setEnabled:NO];
    self.adProvider = @"dfp";
    [Spil devRequestAd:self.adProvider withAdType:@"interstitial" withParentalGate:NO];
}

-(void)updateProviderButtons {
    self.fyberRequestButton.backgroundColor = [Spil isAdProviderInitialized:@"fyber"] ? [UIColor greenColor] : [UIColor redColor];
    self.chartboostRequestButton.backgroundColor = [Spil isAdProviderInitialized:@"chartboost"] ? [UIColor greenColor] : [UIColor redColor];
    self.googleRequestButton.backgroundColor = [Spil isAdProviderInitialized:@"dfp"] ? [UIColor greenColor] : [UIColor redColor];
}

/*-(IBAction)onPlayButtonPressed:(id)sender {
    [self.playButton setEnabled:NO];
    [self.playButton setBackgroundColor:[UIColor lightGrayColor]];
    [self updateProviderButtons];
    [Spil devShowInterstitial:self.adProvider];
}*/

#pragma mark delegate

-(void)adAvailable:(NSString*)type {
    if ([type isEqualToString:@"interstitial"]) {
        self.resultTextView.text = @"> Interstitial available!";
        
        /*[self.playButton setEnabled:YES];
        [self.playButton setBackgroundColor:[UIColor greenColor]];*/
    }
}

-(void)adNotAvailable:(NSString*)type {
    if ([type isEqualToString:@"interstitial"]) {
        self.resultTextView.text = @"> Interstitial not available!";
        
        //[self.playButton setBackgroundColor:[UIColor redColor]];
    }
}

-(void)adStart {
    self.resultTextView.text = [NSString stringWithFormat:@"%@ \n> Interstitial started!", self.resultTextView.text];
}

-(void)adFinished:(NSString*)adType reason:(NSString*)reason reward:(NSString*)reward network:(NSString*)network {
    self.resultTextView.text = [NSString stringWithFormat:@"%@ \n> %@ interstitial finished.\nWith type:%@ With reason: %@\nWith reward data: %@", self.resultTextView.text, network, adType, reason, reward];
    
    /*[self.playButton setEnabled:NO];
    [self.playButton setBackgroundColor:[UIColor lightGrayColor]];*/
}

-(void)openParentalGate {
    self.resultTextView.text = @"> openParentalGate!";
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.resultTextView.text = @"> passedParentalGate!";
        [Spil closedParentalGate:true];
    });
}

@end
