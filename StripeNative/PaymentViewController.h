//
//  PaymentViewController.h
//  Stripe
//
//  Created by Alex MacCaw on 3/4/13.
//
//

#import <UIKit/UIKit.h>

@class PaymentViewController;

@protocol PaymentViewControllerDelegate<NSObject>

- (void)paymentViewController:(PaymentViewController *)controller didFinishWithToken:(STPToken *)token email:(NSString *)email error:(NSError *)error;

@end

@interface PaymentViewController : UIViewController

@property (nonatomic) NSString* amount;
@property (nonatomic, weak) id<PaymentViewControllerDelegate> delegate;

@end
