#import <UIKit/UIKit.h>

@interface ConfigViewController : UIViewController<UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *resultTextView;
@property (weak, nonatomic) IBOutlet UITextField *valueTextField;

- (IBAction)onGetAllConfigButtonPressed:(id)sender;
- (IBAction)onGetConfigValueButtonPressed:(id)sender;

@end
