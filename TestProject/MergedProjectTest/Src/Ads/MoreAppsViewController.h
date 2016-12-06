#import <UIKit/UIKit.h>
#import "SpilTV/Spil.h"

@interface MoreAppsViewController : UIViewController<SpilDelegate>

@property (weak, nonatomic) IBOutlet UIButton *chartboostRequestButton;

@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (weak, nonatomic) IBOutlet UITextView *resultTextView;

-(IBAction)onChartboostRequestButtonPressed:(id)sender;

-(IBAction)onPlayButtonPressed:(id)sender;

@end
