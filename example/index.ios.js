var React = require('react-native');
var StripeNative = require('react-native-stripe');

const MERCHANT_ID = "<YOUR APPLE PAY MERCHANT ID>";
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

  componentDidMount() {
    StripeNative.init(STRIPE_KEY, MERCHANT_ID);
  },

  getInitialState() {
    return {
      error: null,
    }
  },

  applePaySuccess() { this.applePay("success") },

  applePayAllInfo() { this.applePay("success", "allinfo") },

  applePayFailure() { this.applePay() },

  applePay(success, allInfo) {
    // These come back as promises.
    Promise.all([StripeNative.canMakePayments(), StripeNative.canMakePaymentsUsingNetworks()]).then(
      function (canMakePayments) {
        if (!canMakePayments[0])
          this.setState({error: "Apple Pay is not enabled on this device"});
        else if (!canMakePayments[1])
          this.setState({error: "Apple Pay is enabled but no card is configured"});
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
      }.bind(this));
  },

  cardForm() {
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

  cardNumber() {
    var STPCardParams = {
      number:   4242424242424242,
      cvc:      123,
      expMonth: 12,
      expYear:  2025,
    };

    StripeNative.createTokenWithCard(STPCardParams).then(function (obj) {

      alert("Got token: " + obj);

      // (Create charge here)

    }, function (err) {
      this.setState({error: "Error getting token"});
    }.bind(this))
  },

  render() {
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
        <TouchableHighlight
          style={styles.selectButton}
          onPress={this.cardNumber}
          underlayColor="#99D9F4">
          <Text style={styles.buttonText}>
            Try Create with Card Number
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
