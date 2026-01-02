import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../NATS Service/NatsService.dart';
import '../../../constants/colorConstant/color_constant.dart';
import '../../../widgets/user_interested_provider_list_card.dart';
import '../AssignedandCompleteUserServiceDetailsScreen.dart';
import '../navigation/BookingProvider.dart';
import 'PaymentOptionsScreen.dart';

class RequestBroadcastScreen extends StatefulWidget {
  final int? userId;
  final String? serviceId;
  final double? latitude;
  final double? longitude;

  // ✅ Add these three new parameters
  final String? categoryName;
  final String? subcategoryName;
  final String? amount;

  const RequestBroadcastScreen({
    Key? key,
    required this.userId,
    required this.serviceId,
    required this.latitude,
    required this.longitude,
    // ✅ Add these
    this.categoryName,
    this.subcategoryName,
    this.amount,
  }) : super(key: key);

  @override
  State<RequestBroadcastScreen> createState() => _RequestBroadcastScreenState();
}

class _RequestBroadcastScreenState extends State<RequestBroadcastScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controller = Completer();
  Map<String, double> _bidTimers = {};
  Map<String, Timer?> _countdownTimers = {};
  final StreamController<Map<String, double>> _timerStreamController =
      StreamController<Map<String, double>>.broadcast();

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  late final LatLng _userLocation;
  late final LatLng _destination;

  late AnimationController _pulseController;
  late AnimationController _searchController;
  late AnimationController _zoomController;

  int _secondsElapsed = 0;
  Timer? _timer;
  Timer? _zoomTimer;
  int _masterTimerSeconds = 0;
  Timer? _masterTimer;

  List<NearbyProvider> _nearbyProviders = [];
  List<AcceptedBid> _acceptedBids = [];
  double _targetZoom = 13.5;
  bool _isZoomingOut = true;
  bool _isDialogShowing = false;
  bool _isLoadingProviders = true;
  bool _isScreenClosed = false;

  final NatsService _natsService = NatsService();

  @override
  void initState() {
    super.initState();

    _userLocation = LatLng(
      widget.latitude ?? 22.7196,
      widget.longitude ?? 75.8577,
    );

    _destination = LatLng(22.7532, 75.8937);

    _initializeAnimations();

    // ADD THIS CHECK: If master timer is at 180, close immediately
    if (_masterTimerSeconds == 180) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isScreenClosed) {
          _closeScreen();
        }
      });
      return; // Don't initialize timers or fetch providers
    }

    _initializeTimers();
    _fetchNearbyProviders();
    _subscribeToNats();
  }

  Future<void> _fetchNearbyProviders() async {
    try {
      setState(() {
        _isLoadingProviders = true;
      });

      final requestData = {'service_id': int.parse(widget.serviceId ?? '0')};

      debugPrint('📤 Requesting nearby providers: $requestData');

      final response = await _natsService.request(
        'provider.nearby.location',
        jsonEncode(requestData),
        timeout: const Duration(seconds: 5),
      );

      if (response != null) {
        final data = jsonDecode(response);
        debugPrint('📥 Nearby providers response: $data');

        if (data['providers'] != null) {
          final providers = (data['providers'] as List)
              .map((p) => NearbyProvider.fromJson(p))
              .toList();

          if (mounted) {
            setState(() {
              _nearbyProviders = providers;
              _isLoadingProviders = false;
            });
          }

          await _setupMarkers();
        }
      } else {
        debugPrint('❌ No response from NATS API');
        if (mounted) {
          setState(() {
            _isLoadingProviders = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching nearby providers: $e');
      if (mounted) {
        setState(() {
          _isLoadingProviders = false;
        });
      }
    }
  }

  void _subscribeToNats() {
    final topic = 'service.accepted.${widget.userId}';
    debugPrint('🎯 Subscribing to NATS topic: $topic');

    _natsService.subscribe(topic, (message) {
      debugPrint('📨 Received bid acceptance: $message');
      _handleBidAcceptance(message);
    });
  }

  void _handleBidAcceptance(String message) {
    if (_isScreenClosed) return;

    try {
      final data = jsonDecode(message);
      final acceptedBid = AcceptedBid.fromJson(data);

      if (mounted) {
        setState(() {
          _acceptedBids.add(acceptedBid);
          _bidTimers[acceptedBid.bidId] = 30.0;
        });
      }

      _startBidTimer(acceptedBid.bidId);

      if (!_isDialogShowing && _acceptedBids.length == 1) {
        _showAcceptedProvidersDialog();
      }
    } catch (e) {
      debugPrint('❌ Error parsing bid acceptance: $e');
    }
  }

  void _startBidTimer(String bidId) {
    _countdownTimers[bidId]?.cancel();

    _countdownTimers[bidId] = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        if (!mounted || _isScreenClosed) {
          timer.cancel();
          return;
        }

        if (_bidTimers[bidId] != null && _bidTimers[bidId]! > 0) {
          _bidTimers[bidId] = _bidTimers[bidId]! - 0.1;
          _timerStreamController.add(Map.from(_bidTimers));
        } else {
          timer.cancel();
          _countdownTimers[bidId]?.cancel();

          if (mounted) {
            setState(() {
              _acceptedBids.removeWhere((bid) => bid.bidId == bidId);
              _bidTimers.remove(bidId);
              _countdownTimers.remove(bidId);
            });
          }

          _timerStreamController.add(Map.from(_bidTimers));
          _checkAndDismissDialog();
        }
      },
    );
  }

  void _checkAndDismissDialog() {
    if (_isDialogShowing && _acceptedBids.isEmpty && mounted) {
      _isDialogShowing = false;
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showAcceptedProvidersDialog() {
    if (_isScreenClosed) return;

    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 20),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          _isDialogShowing = false;
                          Navigator.of(dialogContext).pop();
                          _closeScreen();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.close,
                                size: 20,
                                color: ColorConstant.onSurface,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Cancel Request',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ColorConstant.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_acceptedBids.length} provider${_acceptedBids.length > 1 ? 's' : ''} interested',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _acceptedBids.isEmpty
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.hourglass_empty,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'Waiting for providers...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: StreamBuilder<Map<String, double>>(
                              stream: _timerStreamController.stream,
                              initialData: _bidTimers,
                              builder: (context, snapshot) {
                                final timers = snapshot.data ?? {};

                                return ListView.builder(
                                  itemCount: _acceptedBids.length,
                                  itemBuilder: (context, index) {
                                    final bid = _acceptedBids[index];
                                    final remainingTime =
                                        timers[bid.bidId] ?? 0.0;

                                    return UserInterestedProviderListCard(
                                      providerName:
                                          '${bid.provider.user.firstname ?? 'Provider'} ${bid.provider.user.lastname ?? ''}',
                                      gender: bid.provider.user.gender ?? 'N/A',
                                      age:
                                          bid.provider.user.age?.toString() ??
                                          'N/A',
                                      distance: '${(index + 1) * 0.5} km',
                                      reachTime: '${(index + 1) * 5} min',
                                      category: bid.service.category,
                                      subCategory: bid.service.service,
                                      chargeRate: bid.amount,
                                      isVerified:
                                          bid.provider.user.emailVerified,
                                      rating: '4.${5 + index}',
                                      experience: '${3 + index}',
                                      dp: bid.provider.user.image,
                                      remainingTime: remainingTime,
                                      bidStatus: bid.status,
                                      // Pass the status to the card
                                      onBook: remainingTime > 0
                                          ? () {
                                              _bookProvider(bid, dialogContext);
                                            }
                                          : null,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  void _bookProvider(AcceptedBid bid, BuildContext dialogContext) {
    final bidAmount = double.tryParse(bid.amount) ?? 0.0;

    if (bid.service.serviceDays > 1 && bidAmount > 5000) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentOptionsScreen(
            totalAmount: bidAmount,
            categoryName: widget.categoryName ?? bid.service.category,
            subcategoryName: widget.subcategoryName ?? bid.service.service,
            serviceId: bid.serviceId,
          ),
        ),
      ).then((paymentResult) {
        if (paymentResult != null && paymentResult['status'] == 'success') {
          // Payment successful, proceed with booking
          _confirmBookingAfterPayment(bid, dialogContext, paymentResult);
        }
      });
      return;
    }
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Booking',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Text(
          'Do you want to book ${bid.provider.user.firstname} ${bid.provider.user.lastname} for ₹${bid.amount}?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          Consumer<BookingProvider>(
            builder: (context, bookingProvider, child) {
              return ElevatedButton(
                onPressed: bookingProvider.isLoading
                    ? null
                    : () async {
                        try {
                          final response = await bookingProvider.bookProvider(
                            serviceId: bid.serviceId,
                            providerId: bid.provider.id.toString(),
                          );

                          if (response != null) {
                            Navigator.pop(context);
                            _isDialogShowing = false;
                            Navigator.of(dialogContext).pop();
                            _closeScreen();

                            Navigator.of(this.context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    AssignedandCompleteUserServiceDetailsScreen(
                                      serviceId: bid.serviceId,
                                    ),
                              ),
                            );

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Booking confirmed with ${bid.provider.user.firstname}!',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                backgroundColor: ColorConstant.moyoGreen,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception: ', ''),
                                style: const TextStyle(fontSize: 16),
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstant.moyoOrange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: bookingProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Add this new helper method to handle booking after payment
  void _confirmBookingAfterPayment(
    AcceptedBid bid,
    BuildContext dialogContext,
    Map<String, dynamic> paymentResult,
  ) async {
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );

    try {
      final response = await bookingProvider.bookProvider(
        serviceId: bid.serviceId,
        providerId: bid.provider.id.toString(),
      );

      if (response != null) {
        _isDialogShowing = false;
        Navigator.of(dialogContext).pop();
        _closeScreen();

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AssignedandCompleteUserServiceDetailsScreen(
              serviceId: bid.serviceId,
            ),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking confirmed with ${bid.provider.user.firstname}! Payment: ₹${paymentResult['amount']}',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: ColorConstant.moyoGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _searchController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _initializeTimers() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isScreenClosed) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });

    _masterTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isScreenClosed) {
        timer.cancel();
        return;
      }

      setState(() {
        _masterTimerSeconds++; // Changed from -- to ++
      });

      // CHECK: If timer reaches 180, close screen
      if (_masterTimerSeconds >= 180) {
        timer.cancel();
        _handleMasterTimerExpiry();
      }
    });

    _zoomTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_mapController != null && mounted && !_isScreenClosed) {
        if (_isZoomingOut) {
          _targetZoom -= 0.01;
          if (_targetZoom <= 12.5) {
            _isZoomingOut = false;
          }
        } else {
          _targetZoom += 0.01;
          if (_targetZoom >= 13.5) {
            _isZoomingOut = true;
          }
        }

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _userLocation, zoom: _targetZoom),
          ),
        );
      }
    });
  }

  void _handleMasterTimerExpiry() {
    if (_isScreenClosed) return;

    _isScreenClosed = true;

    if (_isDialogShowing && mounted) {
      _isDialogShowing = false;
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);
    }

    Navigator.of(context).pop();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Request expired. No providers found.',
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_isScreenClosed) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _closeScreen() {
    if (_isScreenClosed) return;
    _isScreenClosed = true;

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<BitmapDescriptor> _getResizedMarkerIcon(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    final Uint8List resizedBytes = (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(resizedBytes);
  }

  Future<void> _setupMarkers() async {
    final Set<Marker> markers = {};
    debugPrint('📍 Loading current location icon...');
    final currentLocationIcon = await _getResizedMarkerIcon(
      'assets/icons/currentmarker.png',
      70,
    );
    debugPrint('✅ Icon loaded successfully');

    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: _userLocation,
        icon: currentLocationIcon,
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ),
    );

    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: _destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Destination'),
      ),
    );

    for (var provider in _nearbyProviders) {
      markers.add(
        Marker(
          markerId: MarkerId('provider_${provider.providerId}'),
          position: LatLng(provider.latitude, provider.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: '${provider.userName} ${provider.lastName}',
            snippet:
                '${provider.distance.toStringAsFixed(2)} km • Skills: ${provider.skills.join(", ")}',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  @override
  void dispose() {
    _isScreenClosed = true;

    _pulseController.dispose();
    _searchController.dispose();
    _zoomController.dispose();
    _timer?.cancel();
    _zoomTimer?.cancel();
    _masterTimer?.cancel();
    _mapController?.dispose();

    _countdownTimers.values.forEach((timer) => timer?.cancel());
    _countdownTimers.clear();

    _timerStreamController.close();

    _natsService.unsubscribe('service.accepted.${widget.userId}');

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _closeScreen();
        return false;
      },
      child: Scaffold(
        backgroundColor: ColorConstant.white,
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _userLocation,
                zoom: 13.5,
              ),
              markers: _markers,
              circles: _circles,
              onMapCreated: (GoogleMapController controller) async {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                  _mapController = controller;
                }
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              rotateGesturesEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: false,
              myLocationEnabled: false,
            ),

            Center(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 150 + (_pulseController.value * 100),
                          height: 150 + (_pulseController.value * 100),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ColorConstant.moyoOrange.withOpacity(
                                0.6 - _pulseController.value * 0.6,
                              ),
                              width: 3,
                            ),
                          ),
                        ),
                        Container(
                          width: 120 + (_pulseController.value * 60),
                          height: 120 + (_pulseController.value * 60),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorConstant.moyoOrange.withOpacity(
                              0.2 - _pulseController.value * 0.2,
                            ),
                          ),
                        ),
                        Container(
                          width: 80 + (_pulseController.value * 30),
                          height: 80 + (_pulseController.value * 30),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorConstant.moyoOrange.withOpacity(
                              0.4 - _pulseController.value * 0.4,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ColorConstant.black.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: ColorConstant.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ColorConstant.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: ColorConstant.black,
                        ),
                        onPressed: () => _closeScreen(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: ColorConstant.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: ColorConstant.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            AnimatedBuilder(
                              animation: _searchController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _searchController.value * 2 * pi,
                                  child: const Icon(
                                    Icons.radar,
                                    color: ColorConstant.moyoOrange,
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _acceptedBids.isEmpty
                                        ? 'Searching for provider...'
                                        : '${_acceptedBids.length} provider${_acceptedBids.length > 1 ? 's' : ''} responded',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _isLoadingProviders
                                        ? 'Loading...'
                                        : '${_nearbyProviders.length} nearby providers',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${_masterTimerSeconds}s',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ColorConstant.moyoOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: ColorConstant.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstant.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle at top
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Category & Subcategory
                    Row(
                      children: [
                        const Text(
                          'Service: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${widget.categoryName ?? 'N/A'} > ${widget.subcategoryName ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: ColorConstant.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Budget',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          '₹${widget.amount ?? '0'}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ColorConstant.moyoOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NearbyProvider {
  final int providerId;
  final int userId;
  final int workRadius;
  final bool notified;
  final String deviceToken;
  final String userName;
  final String lastName;
  final bool isChecked;
  final double latitude;
  final double longitude;
  final List<String> skills;
  final double distance;

  NearbyProvider({
    required this.providerId,
    required this.userId,
    required this.workRadius,
    required this.notified,
    required this.deviceToken,
    required this.userName,
    required this.lastName,
    required this.isChecked,
    required this.latitude,
    required this.longitude,
    required this.skills,
    required this.distance,
  });

  factory NearbyProvider.fromJson(Map<String, dynamic> json) {
    return NearbyProvider(
      providerId: json['provider_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      workRadius: json['work_radius'] ?? 0,
      notified: json['notified'] ?? false,
      deviceToken: json['device_token'] ?? '',
      userName: json['user_name'] ?? '',
      lastName: json['last_name'] ?? '',
      isChecked: json['is_checked'] ?? false,
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
      distance: double.tryParse(json['distance']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class AcceptedBid {
  final String serviceId;
  final String bidId;
  final String amount;
  final String status;
  final ServiceData service;
  final ProviderData provider;
  final String acceptedAt;

  AcceptedBid({
    required this.serviceId,
    required this.bidId,
    required this.amount,
    required this.status,
    required this.service,
    required this.provider,
    required this.acceptedAt,
  });

  factory AcceptedBid.fromJson(Map<String, dynamic> json) {
    return AcceptedBid(
      serviceId: json['service_id'] ?? '',
      bidId: json['bid_id'] ?? '',
      amount: json['amount'] ?? '',
      status: json['status'] ?? 'Accepted',
      // Parse status from JSON
      service: ServiceData.fromJson(json['service'] ?? {}),
      provider: ProviderData.fromJson(json['provider'] ?? {}),
      acceptedAt: json['accepted_at'] ?? '',
    );
  }
}

class ServiceData {
  final String id;
  final String title;
  final String category;
  final String service;
  final String description;
  final String location;
  final String budget;
  final String maxBudget;
  final String tenure;
  final DateTime? scheduleDate;
  final String? scheduleTime;
  final String serviceType;
  final String latitude;
  final String longitude;
  final String serviceMode;
  final int? durationValue;
  final String? durationUnit;
  final int serviceDays; // ✅ ADDED
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final String paymentMethod;
  final String paymentType;
  final Map<String, dynamic>? dynamicFields;

  ServiceData({
    required this.id,
    required this.title,
    required this.category,
    required this.service,
    required this.description,
    required this.location,
    required this.budget,
    required this.maxBudget,
    required this.tenure,
    this.scheduleDate,
    this.scheduleTime,
    required this.serviceType,
    required this.latitude,
    required this.longitude,
    required this.serviceMode,
    this.durationValue,
    this.durationUnit,
    required this.serviceDays, // ✅ ADDED
    this.startDate,
    this.endDate,
    required this.status,
    required this.paymentMethod,
    required this.paymentType,
    this.dynamicFields,
  });

  factory ServiceData.fromJson(Map<String, dynamic> json) {
    return ServiceData(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      service: json['service'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      budget: json['budget']?.toString() ?? '0',
      maxBudget: json['max_budget']?.toString() ?? '0',
      tenure: json['tenure'] ?? '',
      scheduleDate: json['schedule_date'] != null
          ? DateTime.tryParse(json['schedule_date'])
          : null,
      scheduleTime: json['schedule_time'],
      serviceType: json['service_type'] ?? '',
      latitude: json['latitude']?.toString() ?? '0',
      longitude: json['longitude']?.toString() ?? '0',
      serviceMode: json['service_mode'] ?? '',
      durationValue: json['duration_value'],
      durationUnit: json['duration_unit'],
      serviceDays: json['service_days'] ?? 0,
      // ✅ ADDED
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'])
          : null,
      status: json['status'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      paymentType: json['payment_type'] ?? '',
      dynamicFields: json['dynamic_fields'] as Map<String, dynamic>?,
    );
  }
}

class ProviderData {
  final int id;
  final UserData user;

  ProviderData({required this.id, required this.user});

  factory ProviderData.fromJson(Map<String, dynamic> json) {
    return ProviderData(
      id: json['id'] ?? 0,
      user: UserData.fromJson(json['user'] ?? {}),
    );
  }
}

class UserData {
  final int id;
  final String firstname;
  final String lastname;
  final String username;
  final String email;
  final String mobile;
  final String gender;
  final int age;
  final String image;
  final bool emailVerified;

  UserData({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.username,
    required this.email,
    required this.mobile,
    required this.gender,
    required this.age,
    required this.image,
    required this.emailVerified,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      gender: json['gender'] ?? '',
      age: json['age'] ?? 0,
      image: json['image'] ?? '',
      emailVerified: json['email_verified'] ?? false,
    );
  }
}
