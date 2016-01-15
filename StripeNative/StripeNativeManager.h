#import "RCTViewManager.h"
#import "PaymentViewController.h"

@interface StripeNativeManager : NSObject <RCTBridgeModule, PKPaymentAuthorizationViewControllerDelegate, PaymentViewControllerDelegate>

@end
