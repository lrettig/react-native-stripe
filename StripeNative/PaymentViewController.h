//
//  PaymentViewController.h
//
//  Created by Lane Rettig on 1/22/15.
//  Copyright (c) 2015 Lane Rettig. All rights reserved.
//
//  Based on work by Alex MacCaw at Stripe.
//  See https://github.com/stripe/stripe-ios.
//

#import <UIKit/UIKit.h>

@class PaymentViewController;

@protocol PaymentViewControllerDelegate<NSObject>

- (void)paymentViewController:(PaymentViewController *)controller didFinishWithToken:(STPToken *)token email:(NSString *)email error:(NSError *)error;

@end

@interface PaymentViewController : UIViewController

@property (nonatomic) NSString* amount;
@property (nonatomic) NSString* currency;
@property (nonatomic, weak) id<PaymentViewControllerDelegate> delegate;

@end
