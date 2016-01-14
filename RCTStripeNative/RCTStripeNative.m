#import <Stripe/Stripe.h>

#import "RCTStripeNative.h"
#import "RCTLog.h"
#import "ShippingManager.h"
#import "PaymentViewController.h"

@implementation RCTStripeNative
{
    UIButton *_b;
    UIButton *_c;
}

- (id)init
{
    [Stripe setDefaultPublishableKey:@"pk_test_D6vevZF11djvM16vuWQW2OM1"];
  if ((self = [super init])) {
      self.shippingManager = [[ShippingManager alloc] init];
//      _loginButton = [[FBSDKLoginButton alloc] init];
//      _loginButton.readPermissions = @[@"email"];
//      [self addSubview:_loginButton];
      _b = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 150, 75)];
      [_b setTitle:@"Apple Pay" forState:UIControlStateNormal];
      [_b setBackgroundColor:[UIColor redColor]];
      
      _c = [[UIButton alloc] initWithFrame:CGRectMake(0, 75, 150, 75)];
      [_c setTitle:@"Enter Card Info" forState:UIControlStateNormal];
      [_c setBackgroundColor:[UIColor blueColor]];
      
      [_b addTarget:self
             action:@selector(doStripe)
   forControlEvents:UIControlEventTouchUpInside];
      [_c addTarget:self
             action:@selector(beginCustomPayment)
   forControlEvents:UIControlEventTouchUpInside];
      
      [self addSubview:_b];
      [self addSubview:_c];
  }

  return self;
}

- (void)presentError:(NSError *)error {
    NSLog(@"ERROR: %@", error);
//    UIAlertController *controller = [UIAlertController alertControllerWithTitle:nil message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
//    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
//    [controller addAction:action];
//    [self presentViewController:controller animated:YES completion:nil];
}

- (void)paymentSucceeded {
    NSLog(@"SUCCESS");
//    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Success" message:@"Payment successfully created!" preferredStyle:UIAlertControllerStyleAlert];
//    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
//    [controller addAction:action];
//    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Apple Pay

- (BOOL)applePayEnabled {
    if ([PKPaymentRequest class]) {
        PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:@"merchant.com.breezebrand.lanerettig"];
        return [Stripe canSubmitPaymentRequest:paymentRequest];
    }
    return NO;
}

- (void)doStripe
{
    NSLog(@"button pressed");
    
    NSString *merchantId = @"merchant.com.breezebrand.lanerettig";
    
    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:merchantId];
    if ([Stripe canSubmitPaymentRequest:paymentRequest]) {
                [paymentRequest setRequiredShippingAddressFields:PKAddressFieldPostalAddress];
                [paymentRequest setRequiredBillingAddressFields:PKAddressFieldPostalAddress];
                paymentRequest.shippingMethods = [self.shippingManager defaultShippingMethods];
                paymentRequest.paymentSummaryItems = [self summaryItemsForShippingMethod:paymentRequest.shippingMethods.firstObject];
        PKPaymentAuthorizationViewController *auth = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
        auth.delegate = self;
        if (auth) {
            UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
            UIViewController *rootViewController = keyWindow.rootViewController;
            [rootViewController presentViewController:auth animated:YES completion:nil];
        } else {
            NSLog(@"Apple Pay returned a nil PKPaymentAuthorizationViewController - make sure you've configured Apple Pay correctly, as outlined at https://stripe.com/docs/mobile/apple-pay");
        }
    }

}

- (NSArray *)summaryItemsForShippingMethod:(PKShippingMethod *)shippingMethod {
    PKPaymentSummaryItem *shirtItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Cool Shirt" amount:[NSDecimalNumber decimalNumberWithString:@"10.00"]];
    NSDecimalNumber *total = [shirtItem.amount decimalNumberByAdding:shippingMethod.amount];
    PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Stripe Shirt Shop" amount:total];
    return @[shirtItem, shippingMethod, totalItem];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingAddress:(ABRecordRef)address completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKShippingMethod *> * _Nonnull, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {
    [self.shippingManager fetchShippingCostsForAddress:address
                                            completion:^(NSArray *shippingMethods, NSError *error) {
                                                if (error) {
                                                    completion(PKPaymentAuthorizationStatusFailure, @[], @[]);
                                                    return;
                                                }
                                                completion(PKPaymentAuthorizationStatusSuccess,
                                                           shippingMethods,
                                                           [self summaryItemsForShippingMethod:shippingMethods.firstObject]);
                                            }];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingMethod:(PKShippingMethod *)shippingMethod completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {
    completion(PKPaymentAuthorizationStatusSuccess, [self summaryItemsForShippingMethod:shippingMethod]);
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    [[STPAPIClient sharedClient] createTokenWithPayment:payment
                                             completion:^(STPToken *token, NSError *error) {
                                                 NSLog(@"Got token: %@", token);
                                                 //                                                 [self createBackendChargeWithToken:token
                                                 //                                                                         completion:^(STPBackendChargeResult status, NSError *error) {
                                                 //                                                                             if (status == STPBackendChargeResultSuccess) {
                                                 //                                                                                 self.applePaySucceeded = YES;
                                                 //                                                                                 completion(PKPaymentAuthorizationStatusSuccess);
                                                 //                                                                             } else {
                                                 //                                                                                 self.applePayError = error;
                                                 //                                                                                 completion(PKPaymentAuthorizationStatusFailure);
                                                 //                                                                             }
                                                 //                                                                         }];
                                             }];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    UIViewController *rootViewController = keyWindow.rootViewController;
    [rootViewController dismissViewControllerAnimated:YES completion:^{
        NSLog(@"payment authorization VC did finish");
//        if (self.applePaySucceeded) {
//            [self paymentSucceeded];
//        } else if (self.applePayError) {
//            [self presentError:self.applePayError];
//        }
//        self.applePaySucceeded = NO;
//        self.applePayError = nil;
    }];
}

#pragma mark - Custom Credit Card Form

- (void)beginCustomPayment {
    PaymentViewController *paymentViewController = [[PaymentViewController alloc] initWithNibName:nil bundle:nil];
    paymentViewController.amount = [NSDecimalNumber decimalNumberWithString:@"10.00"];
//    paymentViewController.backendCharger = self;
    paymentViewController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:paymentViewController];
//    [self presentViewController:navController animated:YES completion:nil];
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    UIViewController *rootViewController = keyWindow.rootViewController;
    [rootViewController presentViewController:navController animated:YES completion:nil];
}

- (void)paymentViewController:(PaymentViewController *)controller didFinish:(NSError *)error {
    NSLog(@"PaymentViewController did finish");
//    [self dismissViewControllerAnimated:YES completion:^{
//        if (error) {
//            [self presentError:error];
//        } else {
//            [self paymentSucceeded];
//        }
//    }];
}


@end
