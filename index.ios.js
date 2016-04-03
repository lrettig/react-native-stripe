import React, {NativeModules} from 'react-native'
import PaymentButton from './PaymentButton'

var {StripeNativeManager} = NativeModules;

export {PaymentButton};

const iOSConstants = {
  PKAddressFieldNone:           0,
  PKAddressFieldPostalAddress:  1 << 0,
  PKAddressFieldPhone:          1 << 1,
  PKAddressFieldEmail:          1 << 2,
  PKAddressFieldName:           1 << 3,
};

iOSConstants.PKAddressFieldAll =
  iOSConstants.PKAddressFieldPostalAddress|
  iOSConstants.PKAddressFieldPhone|
  iOSConstants.PKAddressFieldEmail|
  iOSConstants.PKAddressFieldName;

export {iOSConstants};

export const Error = {
  SNUserCanceled: 1000, // user canceled Apple Pay
  SNOtherError:   2000, // misc. error
};
export const StripeNativeDomain = "com.lockehart.lib.StripeNative";

export default {

  openPaymentSetup: StripeNativeManager.openPaymentSetup,
  createTokenWithCard: StripeNativeManager.createTokenWithCard,
  success: StripeNativeManager.success,
  failure: StripeNativeManager.failure,

  // Backwards compatibility
  iOSConstants: iOSConstants,
  Error: Error,
  StripeNativeDomain: StripeNativeDomain,

  init: (stripePublishableKey, applePayMerchantId) => {
    return StripeNativeManager.initWithStripePublishableKey(stripePublishableKey, applePayMerchantId);
  },

  canMakePayments() {
    return StripeNativeManager.canMakePayments().then(function (retList) {
      // Data always comes back from native as a list.  We wrap this method to
      // fix that.
      return retList[0];
    });
  },

  canMakePaymentsUsingNetworks() {
    return StripeNativeManager.canMakePaymentsUsingNetworks().then(function (retList) {
      // Data always comes back from native as a list.  We wrap this method to
      // fix that.
      return retList[0];
    });
  },

  paymentRequestWithApplePay(items, merchantName, options) {
    options = options || {};

    // Set up total as last item
    var totalItem = {
      label: merchantName,
      amount: getTotal(items).toString()
    };

    // Set amounts as strings
    var summaryItems = JSON.parse(JSON.stringify(items));
    summaryItems.forEach(function (i) {
      i.amount = i.amount.toString();
    });

    summaryItems.push(totalItem);

    return StripeNativeManager.paymentRequestWithApplePay(summaryItems, options);
  },

  paymentRequestWithCardForm(items) {
    return StripeNativeManager.paymentRequestWithCardForm(getTotal(items).toFixed(2).toString());
  },

};

function getTotal (items) {
  return items.map(i => i.amount).reduce((a,b)=>a+b, 0);
}
