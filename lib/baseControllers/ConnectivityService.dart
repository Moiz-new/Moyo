// connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService {
  ConnectivityService._internal();
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;

  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _controller.stream;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void initialize() {
    // Initial check
    _checkStatus();

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      await _checkStatus(results);
    });
  }

  Future<void> _checkStatus([List<ConnectivityResult>? results]) async {
    results ??= await _connectivity.checkConnectivity();
    final hasNetwork = results.any(
          (e) =>
      e == ConnectivityResult.wifi ||
          e == ConnectivityResult.mobile ||
          e == ConnectivityResult.ethernet,
    );

    bool isOnline = false;
    if (hasNetwork) {
      // Validate actual internet
      isOnline = await InternetConnectionChecker().hasConnection;
    }

    _controller.add(isOnline);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
