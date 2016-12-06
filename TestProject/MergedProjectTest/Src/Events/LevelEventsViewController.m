#import "LevelEventsViewController.h"
#import "SpilTV/Spil.h"

@implementation LevelEventsViewController

- (void)viewDidLoad {
    [self.valueTextField setDelegate:(id<UITextFieldDelegate>)self];
    [self.valueTextField addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [super viewDidLoad];
}

- (IBAction)onLevelStartedButtonPressed:(id)sender {
    NSDictionary *params = @{@"level":self.valueTextField.text};
    [Spil trackEvent:@"levelStart" withParameters:params];
    
    [self.valueTextField resignFirstResponder];
}

- (IBAction)onLevelFinishedButtonPressed:(id)sender {
    NSDictionary *params = @{@"level":self.valueTextField.text};
    [Spil trackEvent:@"levelComplete" withParameters:params];
    
    [self.valueTextField resignFirstResponder];
}

- (IBAction)textFieldFinished:(id)sender
{
    [sender resignFirstResponder];
}

@end
