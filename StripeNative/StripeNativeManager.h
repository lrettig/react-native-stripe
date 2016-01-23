//
//  StripeNativeManager.h
//
//  Created by Lane Rettig on 1/22/15.
//  Copyright (c) 2015 Lane Rettig. All rights reserved.
//

#import "RCTViewManager.h"
#import "PaymentViewController.h"

@interface StripeNativeManager : NSObject <RCTBridgeModule, PKPaymentAuthorizationViewControllerDelegate, PaymentViewControllerDelegate>

@end
