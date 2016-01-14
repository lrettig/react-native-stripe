'use strict';

var {
  StyleSheet,
  Image,
  Text,
  View,
} = React;

var FBLogin = require('react-native-facebook-login');
var FBLoginManager = require('NativeModules').FBLoginManager;

var Login = React.createClass({
  getInitialState: function(){
    return {
      user: null,
    };
  },

  render: function() {
    return (
      <View style={styles.loginContainer}>
        <FBLogin style={styles.fbstyle}/>
      </View>
    );
  }
});

var styles = StyleSheet.create({
  loginContainer: {
    marginTop: 150,

    borderColor: 'green',
    borderWidth: 3,

    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  fbstyle: {
    borderColor: 'blue',
    borderWidth: 3,
  },
});

module.exports = Login;
