import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PaymentBudgetProvider extends ChangeNotifier {
  PaymentBudgetModel? _paymentBudget;
  bool _isLoading = false;
  String? _error;

  // Razorpay instance
  late Razorpay _razorpay;

  // Payment callback
  Function(Map<String, dynamic>)? _onPaymentSuccess;
  Function(String)? _onPaymentError;

  // Store payment context for verification
  String? _currentServiceId;
  String? _currentPaymentType;

  PaymentBudgetModel? get paymentBudget => _paymentBudget;

  bool get isLoading => _isLoading;

  String? get error => _error;

  PaymentBudgetProvider() {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ Payment Success!');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Payment ID: ${response.paymentId}');
    debugPrint('Order ID: ${response.orderId}');
    debugPrint('Signature: ${response.signature}');
    debugPrint('═══════════════════════════════════════');

    // Verify payment with backend
    if (response.paymentId != null && _currentServiceId != null) {
      await _verifyPaymentWithBackend(
        paymentId: response.paymentId!,
        serviceId: _currentServiceId!,
        paymentType: _currentPaymentType ?? 'full',
      );
    } else {
      // Create response data map
      final responseData = {
        'payment_id': response.paymentId,
        'order_id': response.orderId,
        'signature': response.signature,
        'status': 'success',
      };

      Fluttertoast.showToast(
        msg: "Payment Successful!",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.green,
      );

      if (_onPaymentSuccess != null) {
        _onPaymentSuccess!(responseData);
      }
    }
  }

  // Store payment amount for verification
  double? _currentAmount;

  /// Verify payment with backend API
  Future<void> _verifyPaymentWithBackend({
    required String paymentId,
    required String serviceId,
    required String paymentType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      final userId = prefs.getInt('user_id');

      if (authToken == null || authToken.isEmpty) {
        throw Exception('Authentication token not found');
      }

      debugPrint('🔄 Verifying payment with backend...');
      debugPrint('═══════════════════════════════════════');
      debugPrint('Payment ID: $paymentId');
      debugPrint('Service ID: $serviceId');
      debugPrint('User ID: $userId');
      debugPrint('Payment Type: $paymentType');
      debugPrint('Amount: ₹${_currentAmount ?? 0}');
      debugPrint('═══════════════════════════════════════');

      final response = await http.post(
        Uri.parse('$base_url/bid/api/razorpay/capture-Payement'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'user_id': userId,
          'payment_type': paymentType,
          'service_id': serviceId,
          'status': 'captured',
          'payment_id': paymentId,
          'amount': _currentAmount ?? 0,
        }),
      );

      print(response.body);
      debugPrint('📊 Payment Verification Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('═══════════════════════════════════════');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          debugPrint('✅ Payment verified successfully!');

          Fluttertoast.showToast(
            msg: "Payment Successful & Verified!",
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: Colors.green,
          );

          // Create response data for success callback
          final responseData = {
            'payment_id': data['payment_id'] ?? paymentId,
            'order_id': null,
            'signature': null,
            'status': 'success',
            'verified': true,
            'message': data['message'],
          };

          if (_onPaymentSuccess != null) {
            _onPaymentSuccess!(responseData);
          }
        } else {
          throw Exception(data['message'] ?? 'Payment verification failed');
        }
      } else {
        throw Exception('Failed to verify payment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error verifying payment: $e');

      Fluttertoast.showToast(
        msg: "Payment verification failed: $e",
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.orange,
      );

      // Still call success callback with unverified status
      if (_onPaymentSuccess != null) {
        _onPaymentSuccess!({
          'payment_id': paymentId,
          'order_id': null,
          'signature': null,
          'status': 'success',
          'verified': false,
          'error': e.toString(),
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment Error!');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Error Code: ${response.code}');
    debugPrint('Error Message: ${response.message}');
    debugPrint('═══════════════════════════════════════');

    Fluttertoast.showToast(
      msg: "Payment Failed: ${response.message}",
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: Colors.red,
    );

    if (_onPaymentError != null) {
      _onPaymentError!('Payment failed: ${response.message}');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('🔄 External Wallet Selected');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Wallet Name: ${response.walletName}');
    debugPrint('═══════════════════════════════════════');

    Fluttertoast.showToast(
      msg: "External Wallet: ${response.walletName}",
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Future<void> fetchPaymentBudget(String serviceId, double totalAmount) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null || authToken.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$base_url/bid/api/service/$serviceId/payment-budget'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'total_amount': totalAmount}),
      );

      debugPrint('📊 Payment Budget Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _paymentBudget = PaymentBudgetModel.fromJson(data);
        _error = null;

        debugPrint('✅ Payment Budget Loaded Successfully');
      } else {
        throw Exception(
          'Failed to load payment budget: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching payment budget: $e');
      _error = e.toString();
      _paymentBudget = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Open Razorpay checkout
  Future<void> openCheckout({
    required String serviceId,
    required double amount,
    required String paymentType,
    required String userName,
    required String userEmail,
    required String userPhone,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
  }) async {
    _onPaymentSuccess = onSuccess;
    _onPaymentError = onError;
    _currentServiceId = serviceId;
    _currentPaymentType = paymentType;
    _currentAmount = amount;

    final prefs = await SharedPreferences.getInstance();
    final user_id = prefs.getInt('user_id');

    try {
      // Razorpay options
      var options = {
        'key': 'rzp_test_RsAimuNuiOFzpH',
        'amount': (amount * 100).toInt(),
        'name': 'Moyo International',
        'description': 'Service Payment - $paymentType',
        'timeout': 300, // 5 minutes
        'prefill': {'name': userName, 'email': userEmail, 'contact': userPhone},
        'notes': {
          'user_id': user_id?.toString() ?? '',
          'service_id': serviceId,
          'payment_type': paymentType,
        },
        'theme': {'color': '#FF6B35'},
      };

      // Print payment initiation data
      debugPrint('💳 Initiating Razorpay Payment');
      debugPrint('═══════════════════════════════════════');
      debugPrint('Service ID: $serviceId');
      debugPrint('Amount: ₹$amount');
      debugPrint('Payment Type: $paymentType');
      debugPrint('User ID: $user_id');
      debugPrint('User: $userName');
      debugPrint('Email: $userEmail');
      debugPrint('Phone: $userPhone');
      debugPrint('Razorpay Options:');
      debugPrint(json.encode(options));
      debugPrint('═══════════════════════════════════════');

      _razorpay.open(options);
    } catch (e) {
      debugPrint('❌ Error opening Razorpay: $e');
      onError('Failed to initiate payment: $e');
    }
  }

  void clearData() {
    _paymentBudget = null;
    _error = null;
    _isLoading = false;
    _currentServiceId = null;
    _currentPaymentType = null;
    _currentAmount = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}

class PaymentBudgetModel {
  final String serviceId;
  final String title;
  final int serviceDays;
  final double totalAmount;
  final double perDayBidAmount;
  final double suggestionPricePerDay;
  final bool allowPartPayment;
  final PaymentOptions payments;
  final String note;

  PaymentBudgetModel({
    required this.serviceId,
    required this.title,
    required this.serviceDays,
    required this.totalAmount,
    required this.perDayBidAmount,
    required this.suggestionPricePerDay,
    required this.allowPartPayment,
    required this.payments,
    required this.note,
  });

  factory PaymentBudgetModel.fromJson(Map<String, dynamic> json) {
    return PaymentBudgetModel(
      serviceId: json['service_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      serviceDays: json['service_days'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      perDayBidAmount: (json['per_day_bid_amount'] ?? 0).toDouble(),
      suggestionPricePerDay: (json['suggestion_price_per_day'] ?? 0).toDouble(),
      allowPartPayment: json['allow_part_payment'] ?? false,
      payments: PaymentOptions.fromJson(json['payments'] ?? {}),
      note: json['note']?.toString() ?? '',
    );
  }
}

class PaymentOptions {
  final double fullPayment;
  final double partPayment;
  final double halfPayment;

  PaymentOptions({
    required this.fullPayment,
    required this.partPayment,
    required this.halfPayment,
  });

  factory PaymentOptions.fromJson(Map<String, dynamic> json) {
    return PaymentOptions(
      fullPayment: (json['full_payment'] ?? 0).toDouble(),
      partPayment: (json['part_payment'] ?? 0).toDouble(),
      halfPayment: (json['half_payment'] ?? 0).toDouble(),
    );
  }
}
