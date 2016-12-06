#import "PromotionsViewController.h"
#import "SpilTV/Spil.h"

@implementation PromotionsViewController

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
    
    [self onGetAllPromotionsButtonPressed:nil];
}

- (IBAction)onGetAllPromotionsButtonPressed:(id)sender {
    NSString* jsonString = [JsonUtil convertObjectToJson:[Spil getAllPromotions]];
    if (jsonString != nil) {
        self.resultTextView.textColor = [UIColor blackColor];
        self.resultTextView.text = jsonString;
    } else {
        self.resultTextView.textColor = [UIColor redColor];
        self.resultTextView.text = [NSString stringWithFormat:@"PASRSE ERROR"];
    }
    
    [self.valueTextField resignFirstResponder];
}

- (IBAction)onGetPromotionValueButtonPressed:(id)sender {
    NSDictionary *data = [Spil getPromotionByID:self.valueTextField.text];
    
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
