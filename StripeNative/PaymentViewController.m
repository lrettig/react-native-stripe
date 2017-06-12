//
//  PaymentViewController.m
//
//  Created by Lane Rettig on 1/22/15.
//  Copyright (c) 2015 Lane Rettig. All rights reserved.
//
//  Based on work by Alex MacCaw at Stripe.
//  See https://github.com/stripe/stripe-ios.
//

#import <Stripe/Stripe.h>
#import <QuartzCore/QuartzCore.h>

#import "PaymentViewController.h"

@interface PaymentViewController () <STPPaymentCardTextFieldDelegate>
@property (weak, nonatomic) STPPaymentCardTextField *paymentTextField;
// @property (weak, nonatomic) UITextField *emailField;
@property (weak, nonatomic) UIActivityIndicatorView *activityIndicator;
@end

@implementation PaymentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Payment";
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    // Setup save button
    NSString *title = [NSString stringWithFormat:@"Pay %@%@", self.currency, self.amount];
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleDone target:self action:@selector(save:)];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    saveButton.enabled = NO;
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = saveButton;

    // Setup payment view
    STPPaymentCardTextField *paymentTextField = [[STPPaymentCardTextField alloc] init];
    paymentTextField.delegate = self;
    self.paymentTextField = paymentTextField;
    [self.view addSubview:paymentTextField];
    
    // // Setup email field: hack it up to look just like the Stripe field
    // UITextField *emailField = [[UITextField alloc] init];
    // [emailField setPlaceholder:@"Email address"];
    // UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 44)];
    // emailField.leftView = paddingView;
    // emailField.leftViewMode = UITextFieldViewModeAlways;
    // emailField.layer.cornerRadius = 5.0f;
    // emailField.layer.borderColor = [[UIColor colorWithRed:171.0/255.0
    //                                                 green:171.0/255.0
    //                                                  blue:171.0/255.0
    //                                                 alpha:1.0] CGColor];
    // emailField.layer.borderWidth = 1.0f;
    // [emailField addTarget:self
    //               action:@selector(textFieldDidChange)
    //     forControlEvents:UIControlEventEditingChanged];
    // self.emailField = emailField;
    // [self.view addSubview:emailField];
    
    // Setup Activity Indicator
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator = activityIndicator;
    [self.view addSubview:activityIndicator];
}

// - (BOOL)emailFieldIsValid {
//     NSString *emailRegex =
//     @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
//     @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
//     @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
//     @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
//     @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
//     @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
//     @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
//     NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex];
//     return [emailTest evaluateWithObject:self.emailField.text];
// }

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat padding = 15;
    CGFloat width = CGRectGetWidth(self.view.frame) - (padding * 2);
    self.paymentTextField.frame = CGRectMake(padding, padding, width, 44);
    // self.emailField.frame = CGRectMake(padding, padding*2+44, width, 44);
    self.activityIndicator.center = self.view.center;
}

- (void)paymentCardTextFieldDidChange:(nonnull STPPaymentCardTextField *)textField {
    self.navigationItem.rightBarButtonItem.enabled = textField.isValid; // && [self emailFieldIsValid];
}

- (void)textFieldDidChange {
    self.navigationItem.rightBarButtonItem.enabled = self.paymentTextField.isValid; // && [self emailFieldIsValid];
}

- (void)cancel:(id)sender {
    // Just call the delegate method without any data.  It can decide how to handle this.
    // (Alternatively, we could call a separate delegate method in case of cancel, or even
    // have both save and cancel cases call a second didFinish method like
    // PKPaymentAuthorizationViewController.)
    NSLog(@"User canceled payment view controller");
    [self.delegate paymentViewController:self didFinishWithToken:nil email:nil error:nil];
}

- (void)save:(id)sender {
    if (!([self.paymentTextField isValid])) {
        return;
    }
    if (![Stripe defaultPublishableKey]) {
        NSError *error = [NSError errorWithDomain:StripeDomain
                                             code:STPInvalidRequestError
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey: @"Please specify a Stripe Publishable Key"
                                                    }];
        [self.delegate paymentViewController:self didFinishWithToken:nil email:nil error:error];
        return;
    }
    
    [self.activityIndicator startAnimating];
    [[STPAPIClient sharedClient] createTokenWithCard:self.paymentTextField.cardParams
                                          completion:^(STPToken *token, NSError *error) {
                                              [self.activityIndicator stopAnimating];
                                              if (error) {
                                                  [self.delegate paymentViewController:self didFinishWithToken:nil email:nil error:error];
                                              }
                                              NSLog(@"Successfully got token: %@", token);
                                              [self.delegate paymentViewController:self didFinishWithToken:token email:nil error:nil];
                                          }];
}

@end
