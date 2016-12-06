#import <UIKit/UIKit.h>

@interface LevelEventsViewController : UIViewController<UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *resultTextView;
@property (weak, nonatomic) IBOutlet UITextField *valueTextField;

- (IBAction)onLevelStartedButtonPressed:(id)sender;
- (IBAction)onLevelFinishedButtonPressed:(id)sender;

@end
