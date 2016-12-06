#import <UIKit/UIKit.h>

@interface PackagesViewController : UIViewController<UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *resultTextView;
@property (weak, nonatomic) IBOutlet UITextField *valueTextField;

- (IBAction)onGetAllPackagesButtonPressed:(id)sender;
- (IBAction)onGetPackageValueButtonPressed:(id)sender;

@end