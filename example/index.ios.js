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

var {
  AppRegistry,
  StyleSheet,
  Text,
  TouchableHighlight,
  View,
} = React;

var AppEntry = React.createClass({

  componentDidMount: function () {
    StripeNative.init(STRIPE_KEY);
  },

  getInitialState: function () {
    return {
      error: null,
    }
  },

  applePaySuccess: function () { this.applePay("success") },

  applePayAllInfo: function () { this.applePay("success", "allinfo") },

  applePayFailure: function () { this.applePay() },

  applePay: function (success, allInfo) {
    if (!StripeNative.canMakePayments()) {
      this.setState({error: "Apple Pay is not enabled on this device"});
    }
    else if (!StripeNative.canMakePaymentsUsingNetworks()) {
      this.setState({error: "Apple Pay is enabled but no card is configured"});
    }
    else {
      var options = {
        fallbackOnCardForm: false,
        shippingAddressFields: allInfo ?
          StripeNative.iOSConstants.PKAddressFieldAll : StripeNative.iOSConstants.PKAddressFieldNone,
      };
      StripeNative.paymentRequestWithApplePay(SOME_ITEMS, "Llama Kitty Shop", options).then(function (obj) {
        var token = obj[0],
          shippingInfo = obj[1],
          billingInfo = obj[2];

        alert("Got token: " + token);
        console.log("Shipping info: " + JSON.stringify(shippingInfo));
        console.log("Billing info: " + JSON.stringify(billingInfo));

        // (Create charge here)

        (success ? StripeNative.success : StripeNative.failure)();
      }, function (err) {
        console.log("Got err: " + JSON.stringify(err));
        this.setState({error: "Error getting token"});
      }.bind(this))
    }
  },

  cardForm: function () {
    StripeNative.paymentRequestWithCardForm(SOME_ITEMS).then(function (obj) {
      var token = obj[0],
        shippingInfo = obj[1];

      alert("Got token: " + token);
      alert("Got email: " + shippingInfo.emailAddress);

      // (Create charge here)

    }, function (err) {
      this.setState({error: "Error getting token"});
    }.bind(this))
  },

  render: function () {
    return (
      <View style={styles.container}>
        <Text style={styles.error}>
          {this.state.error}
        </Text>
        <Text />
        <TouchableHighlight
          style={styles.selectButton}
          onPress={this.applePaySuccess}
          underlayColor="#99D9F4">
          <Text style={styles.buttonText}>
            Try Apple Pay (Success)
          </Text>
        </TouchableHighlight>
        <TouchableHighlight
          style={styles.selectButton}
          onPress={this.applePayAllInfo}
          underlayColor="#99D9F4">
          <Text style={styles.buttonText}>
            Try Apple Pay All Info (Success)
          </Text>
        </TouchableHighlight>
        <TouchableHighlight
          style={styles.selectButton}
          onPress={this.applePayFailure}
          underlayColor="#99D9F4">
          <Text style={styles.buttonText}>
            Try Apple Pay (Failure)
          </Text>
        </TouchableHighlight>
        <TouchableHighlight
          style={styles.selectButton}
          onPress={() => StripeNative.openPaymentSetup()}
          underlayColor="#99D9F4">
          <Text style={styles.buttonText}>
            Open Apple Pay Card Setup
          </Text>
        </TouchableHighlight>
        <TouchableHighlight
          style={styles.selectButton}
          onPress={this.cardForm}
          underlayColor="#99D9F4">
          <Text style={styles.buttonText}>
            Try Card Form
          </Text>
        </TouchableHighlight>

      </View>
    );
  }
});

var styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 64,
    padding: 20,
  },
  error: {
    color: "red",
    textAlign: "center",
  },
  selectButton: {
    height: 36,
    backgroundColor: '#6AA6C5',
    borderColor: '#6AA6C5',
    borderWidth: 1,
    borderRadius: 8,
    marginBottom: 10,
    alignSelf: 'stretch',
    justifyContent: 'center'
  },
  buttonText: {
    fontSize: 18,
    color: 'white',
    alignSelf: 'center'
  },
});

AppRegistry.registerComponent('example', () => AppEntry);

module.exports = AppEntry;
