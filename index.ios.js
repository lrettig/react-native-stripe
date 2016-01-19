var React = require('react-native');
var NativeModules = React.NativeModules;
var { StripeNativeManager } = NativeModules;

var NativeStripe = {

  canMakePaymentsUsingNetworks: StripeNativeManager.canMakePaymentsUsingNetworks,
  createTokenWithCardForm: StripeNativeManager.createTokenWithCardForm,
  openPaymentSetup: StripeNativeManager.openPaymentSetup,
  success: StripeNativeManager.success,
  failure: StripeNativeManager.failure,

  init: (stripePublishableKey, applePayMerchantId) => {
    return StripeNativeManager.initWithStripePublishableKey(stripePublishableKey, applePayMerchantId);
  },

  canMakePayments: () => {
    return StripeNativeManager.canMakePayments().then(function (retList) {
      // Data always comes back from native as a list.  We wrap this method to
      // fix that.
      return retList[0];
    });
  },

  createTokenWithApplePay: (items, merchantName, fallbackOnCardForm) => {
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

    return StripeNativeManager.createTokenWithApplePay(summaryItems, [], fallbackOnCardForm);
  },
};

getTotal = (items) => {
  return items.map(i => i.amount).reduce((a,b)=>a+b, 0);
};

module.exports = NativeStripe;
