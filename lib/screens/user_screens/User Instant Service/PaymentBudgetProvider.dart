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

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('✅ Payment Success: ${response.paymentId}');
    Fluttertoast.showToast(
      msg: "Payment Successful!",
      toastLength: Toast.LENGTH_SHORT,
      backgroundColor: Colors.green,
    );

    if (_onPaymentSuccess != null) {
      _onPaymentSuccess!({
        'payment_id': response.paymentId,
        'order_id': response.orderId,
        'signature': response.signature,
        'status': 'success',
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment Error: ${response.code} - ${response.message}');
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
    debugPrint('🔄 External Wallet: ${response.walletName}');
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
        Uri.parse('https://api.moyointernational.com/bid/api/service/$serviceId/payment-budget'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'total_amount': totalAmount,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _paymentBudget = PaymentBudgetModel.fromJson(data);
        _error = null;
      } else {
        throw Exception('Failed to load payment budget: ${response.statusCode}');
      }
    } catch (e) {
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

    try {
      // Create order from backend




      // Razorpay options
      var options = {
        'key': 'rzp_test_RsAimuNuiOFzpH',
        'amount': (amount * 100).toInt(), // Amount in paise
        'name': 'Moyo International',
        'description': 'Service Payment - $paymentType',
        'timeout': 300, // 5 minutes
        'prefill': {
          'contact': userPhone,
          'email': userEmail,
          'name': userName,
        },
        'theme': {
          'color': '#FF6B35', // Your brand color
        },
        'notes': {
          'service_id': serviceId,
          'payment_type': paymentType,
        },
      };

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