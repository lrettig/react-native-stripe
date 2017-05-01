# React Native : Stripe SDK

Wraps the native [Stripe iOS SDK](https://github.com/stripe/stripe-ios) for React Native apps.

## Features
- Collect credit card information and convert to a Stripe token, all in native code.
- Get billing and shipping information (name, address, phone number, email address) from Apple Pay.
- Fall back on simple Stripe native credit card form for older devices.
- Check if the device supports Apple Pay, and if so, whether it has cards configured.
- If not, you can prompt the user to configure Apple Pay and enter a card.
- Specify which fields to request from the user in Apple Pay: name, postal address, phone number, and/or email.
- Collect credit card details in JavaScript and convert them to a card token (without needing to use the Stripe JS SDK).
- All methods return promises.

## Caveats
- Stripe only allows you to exchange card information for a payment token on
  the frontend. This *does not actually verify the payment information*. It just
  checks that it _looks_ reasonable, e.g., that the number has the right format,
  that the expiration date is in the future, etc. You should get this token, and
  then immediately pass it to a backend function that validates it, either by
  creating a charge, or else by attaching it to a customer. See the [Stripe API]
  (https://stripe.com/docs/api) for more information, and [this helpful blog
  post] (http://www.larryullman.com/2013/01/30/handling-stripe-errors/) for more
  on handling Stripe errors.
- As a corollary, you should only embed your _Stripe publishable key_ in a
  frontend app.

## Installation

- Install [Stripe iOS SDK](https://stripe.com/docs/mobile/ios)
- Install the module:
```
npm i react-native-stripe --save
```
- Run ```open node_modules/react-native-stripe```
- Drag `StripeNative.xcodeproj` into your `Libraries` group
- Select your main project in the navigator to bring up settings
- Under `Build Phases` expand the `Link Binary With Libraries` header
- Scroll down and click the `+` to add a library
- Find and add `libStripeNative.a` and `libStripe.a` under the `Workspace` group
- ⌘+B

## Example
```javascript
var React = require('react-native');
var StripeNative = require('react-native-stripe');

const STRIPE_KEY = "<YOUR STRIPE KEY>";

const SOME_ITEMS = [
  {
    label: "Llama Kitty T-shirt",
    amount: 19.99,
  },
  {
    label: "Hello Kitty Humidifier",
    amount: 25.00,
  },
];

var AppEntry = React.createClass({

  componentDidMount: function () {
    StripeNative.init(STRIPE_KEY);
  },

  applePay: function () {
    Promise.all([StripeNative.canMakePayments(), StripeNative.canMakePaymentsUsingNetworks()]).then(
      function (canMakePayments) {
        if (!canMakePayments[0])
          alert("Apple Pay is not enabled on this device");
        else if (!canMakePayments[1])
          alert("Apple Pay is enabled but no card is configured");
        else {
          var options = {
            fallbackOnCardForm: false,
            shippingAddressFields: StripeNative.iOSConstants.PKAddressFieldAll,
            currencyCode: 'USD'
          };
          StripeNative.paymentRequestWithApplePay(SOME_ITEMS, "Llama Kitty Shop", options).then(function (obj) {
            var token = obj[0],
              shippingInfo = obj[1],
              billingInfo = obj[2];

            // (Create charge here)

            (chargeWasSuccessful ? StripeNative.success : StripeNative.failure)();
          }, function (err) {
            alert(err);
          })
        }
      });
  },
});

```

## Sample application

- ```cd node_modules/react-native-stripe/example/```
- Edit `index.ios.js` and replace `<YOUR STRIPE KEY>` with your Stripe publishable key.
- Optionally, replace `<YOUR APPLE PAY MERCHANT ID>` with your merchant ID.  Note that this doesn't matter for testing in the simulator.
- ```npm install```
- ```react-native start```
- ```open ios/example.xcodeproj```
- ⌘+R to run the app in X-code.

## Limitations
- Currently only supports iOS.
- Apple does not currently allow us to get any billing contact info other than a postal address.
- Cannot yet check if payment is possible or request payment using a specific card brand ("Visa", "Amex", etc.).
- Currently only supports Stripe as payment processor.
- The manual card entry form is very vanilla and probably not usable in production.  You should show a user's cart to them at the point of checkout, and present errors directly on this form.  It's meant as a starting point.

## Copyright and license

Code and documentation copyright 2016-2017 Lane M Rettig. Code released under [the MIT license](https://github.com/lrettig/react-native-stripe/blob/master/LICENSE).

[react-native]: http://facebook.github.io/react-native/
[stripe-sdk]: https://github.com/stripe/stripe-ios
