import React, { NativeModules } from 'react-native'
var { StripeNativeManager } = NativeModules;

var NativeStripe = {
  canMakePayments: StripeNativeManager.canMakePayments,
  canMakePaymentsUsingNetworks: StripeNativeManager.canMakePaymentsUsingNetworks,

  init: (stripePublishableKey, applePayMerchantId) => {
    return StripeNativeManager.initWithStripePublishableKey(stripePublishableKey, applePayMerchantId);
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

  createTokenWithCardForm: StripeNativeManager.createTokenWithCardForm,

  success: () => {
    return new Promise(function (resolve, reject) {
      StripeNativeManager.success(function (error) {
        if (error) {
          return reject(error);
        }

        resolve(true);
      });
    });
  },

  failure: () => {
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

getTotal = (items) => {
  return items.map(i => i.amount).reduce((a,b)=>a+b, 0);
};

module.exports = NativeStripe;
