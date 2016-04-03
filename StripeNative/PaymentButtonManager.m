//
//  PaymentButtonManager.m
//  StripeNative
//
//  Created by Lane Rettig on 4/2/16.
//  Copyright © 2016 Lane Rettig. All rights reserved.
//

#import "PaymentButtonManager.h"
@import PassKit;

@implementation PaymentButtonManager

RCT_EXPORT_MODULE()

/**
 Keep it very very simple for now.  As far as I can tell, supporting other
 button types or styles would require wrapping the button in another view
 object that swaps out the button when these properties change, since I don't
 think these can be changed once the button is created.
 **/
- (UIView *)view
{
    return [PKPaymentButton buttonWithType:PKPaymentButtonTypePlain style:PKPaymentButtonStyleWhite];
}

@end
