//
//  CustomEventsViewController.h
//  SpilSDKTestProject
//
//  Created by Frank Slofstra on 31/10/16.
//  Copyright © 2016 Frank Slofstra. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomEventsViewController : UIViewController<UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *eventNameTextField;
@property (weak, nonatomic) IBOutlet UITextView *customDataTextView;
@property (weak, nonatomic) IBOutlet UITextView *resultTextView;

- (IBAction)onSendEventButtonPressed:(id)sender;

@end
