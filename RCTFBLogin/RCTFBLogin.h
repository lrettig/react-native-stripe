#import <Stripe/Stripe.h>

#import "RCTView.h"
#import "ShippingManager.h"
#import "PaymentViewController.h"

@interface RCTFBLogin : RCTView<PaymentViewControllerDelegate, PKPaymentAuthorizationViewControllerDelegate>

@property (nonatomic, assign) NSArray *permissions;
@property (nonatomic) ShippingManager *shippingManager;
@property (nonatomic, assign) NSNumber *loginBehavior;

//- (void)setDelegate:(id<FBSDKLoginButtonDelegate>)delegate;

@end
