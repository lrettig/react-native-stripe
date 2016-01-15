var React = require('react-native');
var StripeNative = require('react-native-stripe');

const STRIPE_KEY = "pk_test_D6vevZF11djvM16vuWQW2OM1";
const APPLEPAY_ID = "merchant.com.breezebrand.lanerettig";

const SOME_ITEMS = [
  {
    label: "Cool Llama T-shirt",
    amount: 19.99,
  },
  {
    label: "Hello Kitty Humidifier",
    amount: 25.00,
  },
];

// Make react global
//window.React = React;

var {
  AppRegistry,
  //NavigatorIOS,
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

  applePay: function () {
    if (!StripeNative.canMakePayments()) {
      this.setState({error: "Apple Pay is not enabled on this device"});
    }
    else if (!StripeNative.canMakePaymentsUsingNetworks()) {
      this.setState({error: "Apple Pay is enabled but no card is configured"});
    }
    else {
      StripeNative.createTokenWithApplePay(SOME_ITEMS, false).then(function (token) {
        alert("Success! Got token: " + token);

        // Create charge here

        StripeNative.success();
      }, function (err) {
        this.setState({error: err});

      })
    }
  },

  cardForm: function () {
    StripeNative.createTokenWithCardForm(SOME_ITEMS).then(function (token) {
      alert("Success! Got token: " + token);

      // Create charge here

    }, function (err) {
      this.setState({error: err});
    })
  },

  render: function () {
    return (
      //<NavigatorIOS
      //  style={styles.container}
      //  itemWrapperStyle={styles.allPages}
      //  initialRoute={{
      //    title: 'Login',
      //    component: Login,
      //  }}
      ///>
      <View style={styles.container}>
        <Text style={styles.error}>
          {this.state.error}
        </Text>
        <TouchableHighlight
          style={styles.selectButton}
          onPress={this.applePay}
          underlayColor="#99D9F4">
          <Text style={styles.buttonText}>
            Try Apple Pay
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
