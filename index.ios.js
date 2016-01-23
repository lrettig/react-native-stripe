var React = require('react-native');
var NativeModules = React.NativeModules;
var { StripeNativeManager } = NativeModules;

var iOSConstants = {
  PKAddressFieldNone:           0,
  PKAddressFieldPostalAddress:  1 << 0,
  PKAddressFieldPhone:          1 << 1,
  PKAddressFieldEmail:          1 << 2,
  PKAddressFieldName:           1 << 3,
};
iOSConstants.PKAddressFieldAll =
  iOSConstants.PKAddressFieldPostalAddress|
  iOSConstants.PKAddressFieldPostalAddress|
  iOSConstants.PKAddressFieldPhone|
  iOSConstants.PKAddressFieldEmail|
  iOSConstants.PKAddressFieldName;

var NativeStripe = {

  canMakePaymentsUsingNetworks: StripeNativeManager.canMakePaymentsUsingNetworks,
  paymentRequestWithCardForm: StripeNativeManager.paymentRequestWithCardForm,
  openPaymentSetup: StripeNativeManager.openPaymentSetup,
  success: StripeNativeManager.success,
  failure: StripeNativeManager.failure,

  init: (stripePublishableKey) => {
    // Apple does not seem to care what we set this to.
    var applePayMerchantId = "unused";
    return StripeNativeManager.initWithStripePublishableKey(stripePublishableKey, applePayMerchantId);
  },

  canMakePayments: () => {
    return StripeNativeManager.canMakePayments().then(function (retList) {
      // Data always comes back from native as a list.  We wrap this method to
      // fix that.
      return retList[0];
    });
  },

  paymentRequestWithApplePay: (items, merchantName, options) => {
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
};

getTotal = (items) => {
  return items.map(i => i.amount).reduce((a,b)=>a+b, 0);
};

NativeStripe.iOSConstants = iOSConstants;
module.exports = NativeStripe;
