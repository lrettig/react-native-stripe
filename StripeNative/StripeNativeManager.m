//
//  StripeNativeManager.m
//
//  Created by Lane Rettig on 1/22/15.
//  Copyright (c) 2015 Lane Rettig. All rights reserved.
//

#import <Stripe/Stripe.h>

#import "RCTEventDispatcher.h"
#import "RCTLog.h"

#import "PaymentViewController.h"
#import "StripeNativeManager.h"

@import PassKit;

NSString *const StripeNativeDomain = @"com.lockehart.lib";
typedef NS_ENUM(NSInteger, SNErrorCode) {
    SNOtherError = 10, // Generic error
};

@implementation StripeNativeManager
{
    BOOL _initialized;
    NSString *stripePublishableKey;
    NSString *applePayMerchantId;
    UIViewController *rootViewController;
    PKPaymentSummaryItem *summaryItem;
    
    // Save these promises so we can resolve them later.
    RCTPromiseResolveBlock promiseResolver;
    RCTPromiseRejectBlock promiseRejector;
    
    // This completion dismisses the Apple Pay stuff
    void (^applePayCompletion)(PKPaymentAuthorizationStatus);
}

- (id)init {
    if ((self = [super init])) {
        // NOP
    }
    return self;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE();

#pragma mark - Private methods

#pragma mark - Apple Pay

- (BOOL)_canMakePayments {
    return [PKPaymentAuthorizationViewController canMakePayments];
}

- (BOOL)_canMakePaymentsUsingNetworks {
    NSArray *paymentNetworks = @[PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa];
    return [PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:paymentNetworks];
}

- (void)_openPaymentSetup {
    PKPassLibrary* lib = [[PKPassLibrary alloc] init];
    [lib openPaymentSetup];
}

- (void)_beginApplePayWithArgs: (NSDictionary *)args items:(NSArray *)items error:(NSError**)error {
    
    NSUInteger shippingAddressFieldsMask = args[@"shippingAddressFields"] ? [args[@"shippingAddressFields"] integerValue] : 0;
    
    // Setup product, discount, shipping and total
    NSMutableArray *summaryItems = [NSMutableArray array];
    
    for (NSDictionary *i in items) {
        NSLog(@"Item: %@", i[@"label"]);
        PKPaymentSummaryItem *item = [[PKPaymentSummaryItem alloc] init];
        item.label = i[@"label"];
        item.amount = [NSDecimalNumber decimalNumberWithString:i[@"amount"]];
        [summaryItems addObject:item];
    }
    summaryItem = [summaryItems lastObject];
    
    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:applePayMerchantId];
    [paymentRequest setRequiredShippingAddressFields:shippingAddressFieldsMask];
    [paymentRequest setRequiredBillingAddressFields:PKAddressFieldPostalAddress];
    paymentRequest.paymentSummaryItems = summaryItems;
    paymentRequest.merchantIdentifier = applePayMerchantId;
    PKPaymentAuthorizationViewController *auth = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
    auth.delegate = self;
    if (auth) {
        [rootViewController presentViewController:auth animated:YES completion:nil];
    } else {
        NSLog(@"Apple Pay returned a nil PKPaymentAuthorizationViewController - make sure you've configured Apple Pay correctly, as outlined at https://stripe.com/docs/mobile/apple-pay");
        *error = [NSError errorWithDomain:StripeNativeDomain code:SNOtherError userInfo:@{NSLocalizedDescriptionKey:@"Apple Pay configuration error"}];
    }
}

- (NSDictionary *)getContactDetails:(PKContact*)inputContact {
    // Convert token to string and add additional requested information.
    NSMutableDictionary *contactDetails = [[NSMutableDictionary alloc] init];
    
    // Treat name and phone a little differently since we need to format them
    if (inputContact.name)
        [contactDetails setValue:[NSPersonNameComponentsFormatter localizedStringFromPersonNameComponents:inputContact.name style:NSPersonNameComponentsFormatterStyleDefault options:0] forKey:@"name"];
    if (inputContact.phoneNumber)
        [contactDetails setValue:[inputContact.phoneNumber stringValue] forKey:@"phoneNumber"];
    if (inputContact.emailAddress)
        [contactDetails setValue:inputContact.emailAddress forKey:@"emailAddress"];
    for (NSString *elem in @[@"street", @"city", @"state", @"country", @"ISOCountryCode", @"postalCode"]) {
        if ([inputContact.postalAddress respondsToSelector:NSSelectorFromString(elem)])
            [contactDetails setValue:[inputContact.postalAddress valueForKey:elem] forKey:elem];
    }
    
    return contactDetails;
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion
{
    // Hold onto this until we know whether the payment succeeded or failed
    applePayCompletion = completion;
    
    // Exchange payment for a Stripe token
    [[STPAPIClient sharedClient] createTokenWithPayment:payment completion:^(STPToken *token, NSError *error) {
        if (error) {
            completion(PKPaymentAuthorizationStatusFailure);
            promiseRejector(error);
        }
        else {
            promiseResolver(@[
                              token.tokenId,
                              [self getContactDetails:payment.shippingContact],
                              [self getContactDetails:payment.billingContact],
                              ]);
            [rootViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

-(void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller
{
    NSLog(@"Payment Authorization Controller dismissed.");
    [rootViewController dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark - Card form

- (void)beginCustomPaymentWithAmount:(NSString *)amount {
    PaymentViewController *paymentViewController = [[PaymentViewController alloc] initWithNibName:nil bundle:nil];
    paymentViewController.amount = amount;
    paymentViewController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:paymentViewController];
    [rootViewController presentViewController:navController animated:YES completion:nil];
}

- (void)paymentViewController:(PaymentViewController *)controller didFinishWithToken:(STPToken *)token email:(NSString *)email error:(NSError *)error {
    [rootViewController dismissViewControllerAnimated:YES completion:^{
        if (error) {
            promiseRejector(error);
        } else {
            // Convert token to string and add additional information
            promiseResolver(@[
                              token.tokenId,
                              @{@"emailAddress": email},
                              @{},
                              ]);
        }
    }];
}

#pragma mark - Public methods

RCT_EXPORT_METHOD(initWithStripePublishableKey:(NSString *)stripeKey applePayMerchantId:(NSString *)merchantId) {
    _initialized = TRUE;
    applePayMerchantId = merchantId;
    [Stripe setDefaultPublishableKey:stripeKey];
    rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
}

RCT_EXPORT_METHOD(canMakePayments: (RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject) {
    resolve(@[[NSNumber numberWithBool:[self _canMakePayments]]]);
}

RCT_EXPORT_METHOD(canMakePaymentsUsingNetworks: (RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject) {
    resolve(@[[NSNumber numberWithBool:[self _canMakePaymentsUsingNetworks]]]);
}

RCT_EXPORT_METHOD(openPaymentSetup) {
    [self _openPaymentSetup];
}

RCT_EXPORT_METHOD(paymentRequestWithApplePay: (NSArray *)items args:(NSDictionary *)args resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject) {
    
    NSError *error = nil;
    
    // First try Apple pay
    if ([self _canMakePayments]) {
        promiseResolver = resolve;
        promiseRejector = reject;
        [self _beginApplePayWithArgs:args items:items error:&error];
        if (error)
            reject(error);
    }
    else if (args[@"fallbackOnCardForm"]) {
        [self paymentRequestWithCardForm:items resolver:resolve rejector:reject];
    }
    else {
        reject([NSError errorWithDomain:StripeNativeDomain code:SNOtherError userInfo:@{NSLocalizedDescriptionKey:@"Apple Pay not enabled and fallback option false"}]);
    }
}

RCT_EXPORT_METHOD(paymentRequestWithCardForm:(NSArray *)items resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject) {
    promiseResolver = resolve;
    promiseRejector = reject;
    
    // Get total from last item
    [self beginCustomPaymentWithAmount:[[items lastObject][@"amount"] stringValue]];
}

RCT_EXPORT_METHOD(success: (RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    if (applePayCompletion)
        applePayCompletion(PKPaymentAuthorizationStatusSuccess);
    resolve(@[[NSNull null]]);
}

RCT_EXPORT_METHOD(failure: (RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    if (applePayCompletion)
        applePayCompletion(PKPaymentAuthorizationStatusFailure);
    resolve(@[[NSNull null]]);
}

@end
