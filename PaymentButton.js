/**
 * Created by rettig on 4/2/16.
 */
import React, {
  StyleSheet,
  TouchableWithoutFeedback,
  requireNativeComponent,
} from 'react-native'

var NativeButton = requireNativeComponent('PaymentButton', null);
var styles = StyleSheet.create({
  button: {
    height: 36,
    borderWidth: 1,
    borderRadius: 8,
    alignSelf: 'stretch',
  }
});

export default function PaymentButton (props) {
  var style = props.style ? props.style : styles.button;
  return (
    <TouchableWithoutFeedback onPress={props.onPress} style={style}>
      <NativeButton style={style}/>
    </TouchableWithoutFeedback>
  );
}

// These aren't used yet.  We still need to add native support for these.

// See https://developer.apple.com/library/ios/documentation/PassKit/Reference/PKPaymentButton_Class/index.html#//apple_ref/c/tdef/PKPaymentButtonType
// export var PKPaymentButtonType = {
//   PKPaymentButtonTypePlain: 0,
//   PKPaymentButtonTypeBuy: 1,
//   PKPaymentButtonTypeSetUp: 2,
// };

// See https://developer.apple.com/library/ios/documentation/PassKit/Reference/PKPaymentButton_Class/index.html#//apple_ref/c/tdef/PKPaymentButtonStyle
// export var PKPaymentButtonStyle = {
//   PKPaymentButtonStyleWhite: 0,
//   PKPaymentButtonStyleWhiteOutline: 1,
//   PKPaymentButtonStyleBlack: 2,
// };
