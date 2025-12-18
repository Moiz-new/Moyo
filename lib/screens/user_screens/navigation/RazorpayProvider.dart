import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayProvider extends ChangeNotifier {
  late Razorpay _razorpay;
  bool _isProcessing = false;
  String? _paymentId;
  String? _errorMessage;

  // Razorpay test key
  static const String RAZORPAY_KEY = "rzp_test_RsAimuNuiOFzpH";

  bool get isProcessing => _isProcessing;
  String? get paymentId => _paymentId;
  String? get errorMessage => _errorMessage;

  RazorpayProvider() {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _isProcessing = false;
    _paymentId = response.paymentId;
    _errorMessage = null;
    notifyListeners();
    debugPrint('✅ Payment Success: ${response.paymentId}');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _isProcessing = false;
    _paymentId = null;
    _errorMessage = '${response.code} - ${response.message}';
    notifyListeners();
    debugPrint('❌ Payment Error: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _isProcessing = false;
    notifyListeners();
    debugPrint('🔗 External Wallet: ${response.walletName}');
  }

  /// Open Razorpay payment checkout
  ///
  /// [amount] - Amount in INR (will be converted to paise)
  /// [name] - Name of the customer
  /// [description] - Payment description
  /// [email] - Customer email (optional)
  /// [contact] - Customer phone number (optional)
  /// [orderId] - Order ID from your backend (optional)
  Future<void> openCheckout({
    required double amount,
    required String name,
    required String description,
    String? email,
    String? contact,
    String? orderId,
  }) async {
    _isProcessing = true;
    _paymentId = null;
    _errorMessage = null;
    notifyListeners();

    var options = {
      'key': RAZORPAY_KEY,
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'Moyo International',
      'description': description,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': contact ?? '',
        'email': email ?? '',
      },
      'external': {
        'wallets': ['paytm', 'phonepe', 'googlepay']
      }
    };

    // Add order_id if provided (for server-side order creation)
    if (orderId != null && orderId.isNotEmpty) {
      options['order_id'] = orderId;
    }

    try {
      _razorpay.open(options);
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'Error opening Razorpay: $e';
      notifyListeners();
      debugPrint('❌ Error opening Razorpay: $e');
    }
  }

  /// Reset payment state
  void resetPaymentState() {
    _isProcessing = false;
    _paymentId = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}