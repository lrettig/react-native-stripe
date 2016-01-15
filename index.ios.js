var React = require('react-native');
var {
  NativeModules,
  } = React;

var { StripeNativeManager } = NativeModules;

var NativeStripe = {
  canMakePayments: StripeNativeManager.canMakePayments,
  canMakePaymentsUsingNetworks: StripeNativeManager.canMakePaymentsUsingNetworks,

  init: function (stripePublishableKey, applePayMerchantId) {
    return StripeNativeManager.initWithStripePublishableKey(stripePublishableKey, applePayMerchantId);
  },

  createTokenWithApplePay: function (items, fallbackOnCardForm) {
    // Mutable copy of items
    //var summaryItems = JSON.parse(JSON.stringify(items));

    // Set amounts as strings
    var summaryItems = items.map(function (i) {
      i.amount = i.amount.toString();
    });

    return StripeNativeManager.createTokenWithApplePay(summaryItems, [], fallbackOnCardForm);
  },

  createTokenWithCardForm: StripeNativeManager.createTokenWithCardForm,

  success: function () {
    return new Promise(function (resolve, reject) {
      StripeNativeManager.success(function (error) {
        if (error) {
          return reject(error);
        }

        resolve(true);
      });
    });
  },

  failure: function () {
    return new Promise(function (resolve, reject) {
      StripeNativeManager.failure(function (error) {
        if (error) {
          return reject(error);
        }

        resolve(true);
      });
    });
  },
};

module.exports = NativeStripe;
