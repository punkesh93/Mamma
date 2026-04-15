import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class RazorpayService {
  late Razorpay _razorpay;
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (onSuccess != null) onSuccess!(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (onFailure != null) onFailure!(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (onExternalWallet != null) onExternalWallet!(response);
  }

  void openCheckout({
    required double amount,
    required String contact,
    required String email,
    required String description,
  }) {
    var options = {
      'key': ApiConstants.razorpayKey,
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'MammaBuddy',
      'description': description,
      'prefill': {'contact': contact, 'email': email},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error starting Razorpay checkout: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
