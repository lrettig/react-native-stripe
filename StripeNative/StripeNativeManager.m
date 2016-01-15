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
//    RCTStripeNative *_fbLogin;
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

- (void)_beginApplePayWithItems:(NSArray *)items shippingMethods:(NSArray *)shippingMethods error:(NSError**)error {
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

//    PKPaymentRequest *paymentRequest = [[PKPaymentRequest alloc] init];
    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:applePayMerchantId];
    [paymentRequest setRequiredShippingAddressFields:PKAddressFieldPostalAddress|PKAddressFieldEmail|PKAddressFieldName];
    [paymentRequest setRequiredBillingAddressFields:PKAddressFieldPostalAddress|PKAddressFieldEmail|PKAddressFieldName];
//        paymentRequest.shippingMethods = [shippingManager defaultShippingMethods];
    paymentRequest.paymentSummaryItems = summaryItems;
    paymentRequest.merchantIdentifier = applePayMerchantId;
    PKPaymentAuthorizationViewController *auth = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
    auth.delegate = self;
    if (auth) {
        [rootViewController presentViewController:auth animated:YES completion:nil];
    } else {
        NSLog(@"Apple Pay returned a nil PKPaymentAuthorizationViewController - make sure you've configured Apple Pay correctly, as outlined at https://stripe.com/docs/mobile/apple-pay");
        *error = [NSError errorWithDomain:StripeNativeDomain code:SNOtherError userInfo:@{NSLocalizedDescriptionKey:@"Configuration error"}];
    }
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
            // Convert token to string and add additional requested information.
            promiseResolver(@[[NSString stringWithFormat:@"%@", token],
                              @{
                                  @"street": payment.shippingContact.postalAddress.street,
                                  @"city": payment.shippingContact.postalAddress.city,
                                  @"state": payment.shippingContact.postalAddress.state,
                                  @"country": payment.shippingContact.postalAddress.country,
                                  @"ISOCountryCode": payment.shippingContact.postalAddress.ISOCountryCode,
                                  @"postalCode" : payment.shippingContact.postalAddress.postalCode,
                                  @"emailAddress" : payment.shippingContact.emailAddress ? payment.shippingContact.emailAddress : @"",
                                  @"phoneNumber": payment.shippingContact.phoneNumber ? [payment.shippingContact.phoneNumber stringValue] : @"",
                                  },
                              @{
                                  @"street": payment.billingContact.postalAddress.street,
                                  @"city": payment.billingContact.postalAddress.city,
                                  @"state": payment.billingContact.postalAddress.state,
                                  @"country": payment.billingContact.postalAddress.country,
                                  @"ISOCountryCode": payment.billingContact.postalAddress.ISOCountryCode,
                                  @"postalCode" : payment.billingContact.postalAddress.postalCode,
                                  @"emailAddress" : payment.billingContact.emailAddress ? payment.billingContact.emailAddress : @"",
                                  @"phoneNumber": payment.billingContact.phoneNumber ? [payment.billingContact.phoneNumber stringValue] : @"",
                                  },
                              ]);
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

- (void)paymentViewController:(PaymentViewController *)controller didFinishWithToken:(STPToken *)token error:(NSError *)error {
    [rootViewController dismissViewControllerAnimated:YES completion:^{
        if (error) {
            promiseRejector(error);
        } else {
            // Convert token to string
            NSString *tokenString = [NSString stringWithFormat:@"%@", token];
            promiseResolver(@[tokenString]);
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

RCT_EXPORT_METHOD(createTokenWithApplePay:(NSArray *)items shippingMethods:(NSArray *)shippingMethods fallbackOnCardForm:(BOOL)fallback resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject) {
    
    NSError *error = nil;
    
    // First try Apple pay
    if ([self _canMakePayments]) {
        promiseResolver = resolve;
        promiseRejector = reject;
        [self _beginApplePayWithItems:items shippingMethods:shippingMethods error:&error];
        if (error)
            reject(error);
    }
    else if (fallback) {
        [self createTokenWithCardForm:items resolver:resolve rejector:reject];
    }
    else {
        reject([NSError errorWithDomain:StripeNativeDomain code:SNOtherError userInfo:@{NSLocalizedDescriptionKey:@"Apple Pay not enabled and fallback option false"}]);
    }
}

RCT_EXPORT_METHOD(createTokenWithCardForm:(NSArray *)items resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject) {
    promiseResolver = resolve;
    promiseRejector = reject;
    
    // Get total from last item
    [self beginCustomPaymentWithAmount:[[items lastObject][@"amount"] stringValue]];
}

RCT_EXPORT_METHOD(success:resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    applePayCompletion(PKPaymentAuthorizationStatusSuccess);
    resolve(@[[NSNull null]]);
}

RCT_EXPORT_METHOD(failure:resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    applePayCompletion(PKPaymentAuthorizationStatusFailure);
    resolve(@[[NSNull null]]);
}

@end
