#import <UIKit/UIKit.h>
#import "SpilTV/Spil.h"

@interface RewardVideoViewController : UIViewController<SpilDelegate>

@property (weak, nonatomic) IBOutlet UIButton *fyberRequestButton;
@property (weak, nonatomic) IBOutlet UIButton *chartboostRequestButton;

@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (weak, nonatomic) IBOutlet UITextView *resultTextView;

-(IBAction)onFyberRequestButtonPressed:(id)sender;
-(IBAction)onChartboostRequestButtonPressed:(id)sender;

-(IBAction)onPlayButtonPressed:(id)sender;

@end
