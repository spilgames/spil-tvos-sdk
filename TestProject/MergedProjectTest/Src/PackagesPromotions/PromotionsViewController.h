#import <UIKit/UIKit.h>

@interface PromotionsViewController : UIViewController<UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *resultTextView;
@property (weak, nonatomic) IBOutlet UITextField *valueTextField;

- (IBAction)onGetAllPromotionsButtonPressed:(id)sender;
- (IBAction)onGetPromotionValueButtonPressed:(id)sender;

@end