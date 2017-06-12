//
//  StripeNativeManager.m
//
//  Created by Lane Rettig on 1/22/15.
//  Copyright (c) 2015 Lane Rettig. All rights reserved.
//

#import <Stripe/Stripe.h>

#import "React/RCTEventDispatcher.h"
#import "React/RCTUtils.h"

#import "PaymentViewController.h"
#import "StripeNativeManager.h"

@import PassKit;

NSString *const StripeNativeDomain = @"com.lockehart.lib.StripeNative";
typedef NS_ENUM(NSInteger, SNErrorCode) {
    // RN uses three-digit error codes.  Our error domain is different so it shouldn't
    // matter if there's overlap but use four digit codes just to be safe.
    SNUserCanceled  = 1000, // User canceled Apple Pay
    SNOtherError    = 2000, // Generic error
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
    BOOL resolved;

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
    NSUInteger billingAddressFieldsMask = args[@"billingAddressFields"] ? [args[@"billingAddressFields"] integerValue] : PKAddressFieldPostalAddress;
    NSString* currencyCode = args[@"currencyCode"] ? args[@"currencyCode"] : @"USD";
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
    [paymentRequest setRequiredBillingAddressFields:billingAddressFieldsMask];
    [paymentRequest setCurrencyCode: currencyCode];
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
        resolved = TRUE;
        if (error) {
            completion(PKPaymentAuthorizationStatusFailure);
            promiseRejector(nil, nil, error);
        }
        else {
            promiseResolver(@[
                              token.tokenId,
                              [self getContactDetails:payment.shippingContact],
                              [self getContactDetails:payment.billingContact],
                              ]);
        }
    }];
}

-(void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller
{
    NSLog(@"Payment Authorization Controller dismissed.");
    [rootViewController dismissViewControllerAnimated:YES completion:nil];

    if (!resolved) {
        resolved = TRUE;
        promiseRejector([NSString stringWithFormat:@"%ld", (long)SNUserCanceled], @"User canceled Apple Pay", [[NSError alloc] initWithDomain:StripeNativeDomain code:SNUserCanceled userInfo:@{NSLocalizedDescriptionKey:@"User canceled Apple Pay"}]);
    }
}

# pragma mark - Card form

- (void)beginCustomPaymentWithAmount:(NSString *)amount args:(NSDictionary *)args {

    NSString* currencyCode = args[@"currencySymbol"] ? args[@"currencySymbol"] : @"£";
    
    PaymentViewController *paymentViewController = [[PaymentViewController alloc] initWithNibName:nil bundle:nil];
    paymentViewController.amount = amount;
    paymentViewController.currency = currencyCode;
    paymentViewController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:paymentViewController];
    [rootViewController presentViewController:navController animated:YES completion:nil];
}

- (void)paymentViewController:(PaymentViewController *)controller didFinishWithToken:(STPToken *)token email:(NSString *)email error:(NSError *)error {
    [rootViewController dismissViewControllerAnimated:YES completion:^{
        resolved = TRUE;
        if (error) {
            promiseRejector(nil, nil, error);
        } else {
            // Check if the user canceled the form.
            if (!token) {
                promiseRejector([NSString stringWithFormat:@"%ld", (long)SNUserCanceled], @"User canceled payment", [[NSError alloc] initWithDomain:StripeNativeDomain code:SNUserCanceled userInfo:@{NSLocalizedDescriptionKey:@"User canceled payment"}]);
            }
            else {
                // Convert token to string and add additional information.
                promiseResolver(@[
                                  token.tokenId,
                                  @{},
                                  @{},
                                  ]);
            }
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
        resolved = FALSE;
        [self _beginApplePayWithArgs:args items:items error:&error];
        if (error)
            reject(nil, nil, error);
    }
    else if (args[@"fallbackOnCardForm"]) {
        // The last item for Apple Pay is the "summary" item with the total.
        NSString *amount = [[items lastObject][@"amount"] stringValue];
        [self paymentRequestWithCardForm:amount args:args resolver:resolve rejector:reject];
    }
    else {
        reject(nil, nil, [NSError errorWithDomain:StripeNativeDomain code:SNOtherError userInfo:@{NSLocalizedDescriptionKey:@"Apple Pay not enabled and fallback option false"}]);
    }
}

RCT_EXPORT_METHOD(paymentRequestWithCardForm: (NSString *)amount args:(NSDictionary *)args resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject) {
    promiseResolver = resolve;
    promiseRejector = reject;
    resolved = FALSE;

    [self beginCustomPaymentWithAmount:amount args:args];
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

RCT_EXPORT_METHOD(createTokenWithCard:(NSDictionary *)cardParams resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject) {
    STPCardParams *card = [[STPCardParams alloc] init];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    for (NSString *propertyName in [STPCardParams propertyNamesToFormFieldNamesMapping]) {
        id value = [cardParams objectForKey:propertyName];
        if ([propertyName isEqualToString:@"expMonth"] || [propertyName isEqualToString:@"expYear"]) {
            NSNumber *number = value;
            if ([number isKindOfClass:[NSString class]]) {
                number = [numberFormatter numberFromString:value];
            }
            if (number) {
                [card setValue:number forKey:propertyName];
            }
        } else {
            [card setValue:value forKey:propertyName];
        }
    }
    [[STPAPIClient sharedClient] createTokenWithCard:card
                                          completion:^(STPToken *token, NSError *error) {
                                              if (error == nil) {
                                                  resolve(token.tokenId);
                                              } else {
                                                  reject(nil, nil, error);
                                              }
                                          }];
}

@end
