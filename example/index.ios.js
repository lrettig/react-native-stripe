var React = require('react-native');
var StripeNative = require('react-native-stripe');

const STRIPE_KEY = "pk_test_D6vevZF11djvM16vuWQW2OM1";
const APPLEPAY_ID = "merchant.com.breezebrand.lanerettig";

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
    StripeNative.init(STRIPE_KEY, APPLEPAY_ID);
  },

  getInitialState: function () {
    return {
      error: null,
    }
  },

  applePaySuccess: function () { this.applePay(true) },

  applePayFailure: function () { this.applePay(false) },

  applePay: function (success) {
    if (!StripeNative.canMakePayments()) {
      this.setState({error: "Apple Pay is not enabled on this device"});
    }
    else if (!StripeNative.canMakePaymentsUsingNetworks()) {
      this.setState({error: "Apple Pay is enabled but no card is configured"});
    }
    else {
      StripeNative.createTokenWithApplePay(SOME_ITEMS, "Llama Kitty Shop", false).then(function (token) {
        alert("Got token: " + token);

        // (Create charge here)

        (success ? StripeNative.success : StripeNative.failure)();
      }, function (err) {
        console.log("Got err: " + JSON.stringify(err));
        this.setState({error: "Error getting token"});
      }.bind(this))
    }
  },

  cardForm: function () {
    StripeNative.createTokenWithCardForm(SOME_ITEMS).then(function (token) {
      alert("Got token: " + token);

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
          onPress={this.applePayFailure}
          underlayColor="#99D9F4">
          <Text style={styles.buttonText}>
            Try Apple Pay (Failure)
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
