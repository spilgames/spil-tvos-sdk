#import "PackagesViewController.h"
#import "SpilTV/Spil.h"

@implementation PackagesViewController

- (void)viewDidLoad {
    [self.valueTextField setDelegate:(id<UITextFieldDelegate>)self];
    [self.valueTextField addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.resultTextView.textContainer.lineFragmentPadding = 0;
    self.resultTextView.textContainerInset = UIEdgeInsetsZero;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self onGetAllPackagesButtonPressed:nil];
}

- (IBAction)onGetAllPackagesButtonPressed:(id)sender {
    NSString* jsonString = [JsonUtil convertObjectToJson:[Spil getAllPackages]];
    if (jsonString != nil) {
        self.resultTextView.textColor = [UIColor blackColor];
        self.resultTextView.text = jsonString;
    } else {
        self.resultTextView.textColor = [UIColor redColor];
        self.resultTextView.text = @"PARSE ERROR";
    }
    
    [self.valueTextField resignFirstResponder];
}

- (IBAction)onGetPackageValueButtonPressed:(id)sender {
    NSDictionary *data = [Spil getPackageByID:self.valueTextField.text];
    
    self.resultTextView.textColor = [UIColor blackColor];
    if ([data isKindOfClass:[NSString class]]) {
        self.resultTextView.text = (NSString*)data;
    } else {
        NSString* jsonString = [JsonUtil convertObjectToJson:data];
        if (jsonString != nil) {
            self.resultTextView.text = jsonString;
        } else {
            self.resultTextView.textColor = [UIColor redColor];
            self.resultTextView.text = @"PARSE ERROR";
        }
    }
    
    [self.valueTextField resignFirstResponder];
}

- (IBAction)textFieldFinished:(id)sender
{
    [sender resignFirstResponder];
}

@end
