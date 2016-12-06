#import "AppDelegate.h"
#import "MoreAppsViewController.h"

@interface MoreAppsViewController ()

@end

@implementation MoreAppsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.playButton setEnabled:YES];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [Spil sharedInstance].delegate = self;

    [self updateProviderButtons];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(IBAction)onChartboostRequestButtonPressed:(id)sender {
    [Spil devRequestAd:@"chartboost" withAdType:@"moreApps" withParentalGate:NO]; // TODO parental gate
}

-(IBAction)onPlayButtonPressed:(id)sender {
    [Spil devShowMoreApps:@"chartboost"];
}

-(void)updateProviderButtons {
    self.chartboostRequestButton.backgroundColor = [Spil isAdProviderInitialized:@"chartboost"] ? [UIColor greenColor] : [UIColor redColor];
}

#pragma mark delegate

-(void)adAvailable:(NSString*)type {
    if ([type isEqualToString:@"moreApps"]) {
        self.resultTextView.text = @"> moreApps available!";
        
        [self.playButton setEnabled:YES];
        [self.playButton setBackgroundColor:[UIColor greenColor]];
    }
}

-(void)adNotAvailable:(NSString*)type {
    if ([type isEqualToString:@"moreApps"]) {
        self.resultTextView.text = @"> moreApps not available!";
        
        [self.playButton setBackgroundColor:[UIColor redColor]];
    }
}

-(void)adStart {
    self.resultTextView.text = [NSString stringWithFormat:@"%@ \n> MoreApps started!", self.resultTextView.text];
}

-(void)adFinished:(NSString*)adType reason:(NSString*)reason reward:(NSString*)reward network:(NSString*)network {
    self.resultTextView.text = [NSString stringWithFormat:@"%@ \n> %@ moreApps finished.\nWith adType: %@, reason: %@\nWith reward data: %@", self.resultTextView.text, network, adType, reason, reward];
    
    [self.playButton setEnabled:NO];
    [self.playButton setBackgroundColor:[UIColor lightGrayColor]];
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
