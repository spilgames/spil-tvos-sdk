#import "AppDelegate.h"
#import "MainTableviewController.h"
#import "UserDataVC.h"
#import "SpilTV/Spil.h"
#import "SpilTV/SpilEventTracker.h"

@interface MainTableviewController ()

@end

@implementation MainTableviewController

@synthesize userDataCell;

- (id)initWithCoder:(NSCoder *)aDecoder {
    //[Spil disableAutomaticRegisterForPushNotifications];
    //[Spil setCustomBundleId:@"com.spilgames.tappyplane"];
    [Spil setAdvancedLoggingEnabled:YES];
    [Spil start];
    
    return [super initWithCoder:aDecoder];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [Spil sharedInstance].delegate = self;
    
    [super viewWillAppear:animated];
    self.navigationItem.title = [[SpilEventTracker sharedInstance] getBundleId];
    NSIndexPath *selection = [self.tableView indexPathForSelectedRow];
    if (selection) {
        [self.tableView deselectRowAtIndexPath:selection animated:YES];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationItem.title = @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

# pragma mark Delegates

-(void)adAvailable:(NSString*)type {
    NSLog(@"adAvailable delegate %@", type);
}

-(void)adNotAvailable:(NSString*)type {
    NSLog(@"adNotAvailable delegate %@", type);
}

-(void)adStart {
    NSLog(@"adDidShow delegate");
}

-(void)adFinished:(NSString*)adType reason:(NSString*)reason reward:(NSString*)reward network:(NSString*)network {
    NSLog(@"adFinished delegate, adType: %@, reason: %@, network: %@, reward: %@", adType, reason, network, reward);
}

-(void)grantReward:(NSDictionary*)data {
    NSLog(@"notificationReward delegate %@", data);
}

-(void)packagesLoaded {
    NSLog(@"packagesLoaded delegate");
}

-(void)gameDataAvailable {
    NSLog(@"gameDataAvailable delegate");
}

-(void)configUpdated {
    NSLog(@"configUpdated delegate");
}

-(void)gameDataError:(NSString*)message {
    NSLog(@"gameDataError delegate %@", message);
}

-(void)playerDataAvailable {
    NSLog(@"playerDataAvailable delegate");
}

-(void)playerDataError:(NSString*)message {
    NSLog(@"playerDataError delegate %@", message);
}

-(void)playerDataUpdated:(NSString*)reason updatedData:(NSString*)updatedData {
    NSLog(@"playerDataUpdated delegate");
}

// Splash screen

-(void)splashScreenOpen {
    NSLog(@"splashScreenOpen!");
}

-(void)splashScreenClosed {
    NSLog(@"splashScreenClosed!");
}

-(void)splashScreenOpenShop {
    NSLog(@"splashScreenOpenShop!");
}

-(void)splashScreenError:(NSString*)message {
    NSLog(@"message! %@", message);
}

// Daily bonus

-(void)dailyBonusOpen {
    NSLog(@"dailyBonusOpen!");
}

-(void)dailyBonusClosed {
    NSLog(@"dailyBonusClosed!");
}

-(void)dailyBonusReward:(NSDictionary*)data {
    NSLog(@"dailyBonusReward! %@", data);
}

-(void)dailyBonusError:(NSString*)message {
    NSLog(@"dailyBonusError! %@", message);
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (userDataCell == cell) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UserData" bundle:nil];
        UserDataVC *userDataVC = (UserDataVC*)[storyboard instantiateViewControllerWithIdentifier:@"UserDataVC"];
        [self.navigationController pushViewController:userDataVC animated:true];
        [tableView deselectRowAtIndexPath:indexPath animated:true];
    }
}

@end
