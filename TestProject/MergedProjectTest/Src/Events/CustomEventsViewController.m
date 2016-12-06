//
//  CustomEventsViewController.m
//  SpilSDKTestProject
//
//  Created by Frank Slofstra on 31/10/16.
//  Copyright © 2016 Frank Slofstra. All rights reserved.
//

#import "CustomEventsViewController.h"
#import "SpilTV/Spil.h"
#import "SpilTV/JsonUtil.h"

@interface CustomEventsViewController ()

@end

@implementation CustomEventsViewController

@synthesize eventNameTextField;
@synthesize customDataTextView;
@synthesize resultTextView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.eventNameTextField setDelegate:(id<UITextFieldDelegate>)self];
    [self.eventNameTextField addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    self.eventNameTextField.returnKeyType = UIReturnKeyDone;
    
    self.customDataTextView.delegate = self;
    self.customDataTextView.returnKeyType = UIReturnKeyDone;
}

- (IBAction)onSendEventButtonPressed:(id)sender {
    NSDictionary *jsonData = [JsonUtil convertStringToObject:customDataTextView.text];
    [Spil trackEvent:eventNameTextField.text withParameters:jsonData onResponse:^(id response) {
        resultTextView.text = [JsonUtil convertObjectToJson:response];
    }];
}

- (IBAction)textFieldFinished:(id)sender {
    [sender resignFirstResponder];
}
     
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    [textView resignFirstResponder];
    if ([text isEqualToString:@"\n"]) {
        return NO;
    }
    return YES;
}

@end
