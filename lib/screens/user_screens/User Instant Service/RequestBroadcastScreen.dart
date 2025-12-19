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

class RequestBroadcastScreen extends StatefulWidget {
  final int? userId;

  const RequestBroadcastScreen({Key? key, required this.userId})
    : super(key: key);

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

  static const LatLng _userLocation = LatLng(22.7196, 75.8577);
  static const LatLng _destination = LatLng(22.7532, 75.8937);

  late AnimationController _pulseController;
  late AnimationController _searchController;
  late AnimationController _zoomController;

  int _secondsElapsed = 0;
  Timer? _timer;
  Timer? _zoomTimer;

  List<Provider> _nearbyProviders = [];
  List<AcceptedBid> _acceptedBids = [];
  double _targetZoom = 13.5;
  bool _isZoomingOut = true;
  bool _isDialogShowing = false;

  final NatsService _natsService = NatsService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTimers();
    _generateNearbyProviders();
    _setupMarkers();
    _subscribeToNats();
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
    try {
      final data = jsonDecode(message);
      final acceptedBid = AcceptedBid.fromJson(data);

      setState(() {
        _acceptedBids.add(acceptedBid);
        _bidTimers[acceptedBid.bidId] = 30.0;
      });

      _startBidTimer(acceptedBid.bidId);

      // Show dialog when first bid comes (whether it's the first time or after dialog was dismissed)
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
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_bidTimers[bidId] != null && _bidTimers[bidId]! > 0) {
          _bidTimers[bidId] = _bidTimers[bidId]! - 0.1;
          _timerStreamController.add(Map.from(_bidTimers));
        } else {
          // Time expired, remove the bid
          timer.cancel();
          _countdownTimers[bidId]?.cancel();

          setState(() {
            _acceptedBids.removeWhere((bid) => bid.bidId == bidId);
            _bidTimers.remove(bidId);
            _countdownTimers.remove(bidId);
          });

          _timerStreamController.add(Map.from(_bidTimers));

          // Check if dialog should be dismissed when list becomes empty
          _checkAndDismissDialog();
        }
      },
    );
  }

  // New method to check and dismiss dialog when list is empty
  void _checkAndDismissDialog() {
    if (_isDialogShowing && _acceptedBids.isEmpty) {
      _isDialogShowing = false;
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showAcceptedProvidersDialog() {
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

                  // Cancel button at top-left
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          _isDialogShowing = false;
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).pop();
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

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.transparent,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                                          '${bid.provider.user.firstname} ${bid.provider.user.lastname}',
                                      gender: bid.provider.user.gender,
                                      age: bid.provider.user.age.toString(),
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
      // Reset flag when dialog is dismissed
      _isDialogShowing = false;
    });
  }

  void _bookProvider(AcceptedBid bid, BuildContext dialogContext) {
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
                          // Call the API
                          final response = await bookingProvider.bookProvider(
                            serviceId: bid.serviceId,
                            providerId: bid.provider.id.toString(),
                          );

                          if (response != null) {
                            // Close confirmation dialog
                            Navigator.pop(context);

                            // Close the providers dialog
                            _isDialogShowing = false;
                            Navigator.of(dialogContext).pop();

                            // Close the request broadcast screen
                            Navigator.of(this.context).pop();

                            // Navigate to assigned service details screen
                            Navigator.of(this.context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    AssignedandCompleteUserServiceDetailsScreen(
                                      serviceId: bid.serviceId,
                                    ),
                              ),
                            );

                            // Show success message
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
                          // Show error message
                          Navigator.pop(context); // Close dialog
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
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });

    _zoomTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_mapController != null && mounted) {
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

  void _generateNearbyProviders() {
    final random = Random();
    _nearbyProviders = List.generate(8, (i) {
      return Provider(
        id: 'P${i + 1}',
        name: 'Driver ${i + 1}',
        rating: 4.0 + random.nextDouble(),
        distance: 0.5 + random.nextDouble() * 4,
        location: LatLng(
          _userLocation.latitude + (random.nextDouble() - 0.5) * 0.02,
          _userLocation.longitude + (random.nextDouble() - 0.5) * 0.02,
        ),
      );
    });
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

    final currentLocationIcon = await _getResizedMarkerIcon(
      'assets/icons/currentmarker.png',
      70,
    );

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
          markerId: MarkerId(provider.id),
          position: provider.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: provider.name,
            snippet:
                '${provider.distance.toStringAsFixed(1)} km • ⭐ ${provider.rating.toStringAsFixed(1)}',
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
    _pulseController.dispose();
    _searchController.dispose();
    _zoomController.dispose();
    _timer?.cancel();
    _zoomTimer?.cancel();
    _mapController?.dispose();

    _countdownTimers.values.forEach((timer) => timer?.cancel());
    _countdownTimers.clear();

    _timerStreamController.close();

    _natsService.unsubscribe('service.accepted.${widget.userId}');

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.white,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
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
                      onPressed: () => Navigator.pop(context),
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
                                  '${_nearbyProviders.length} nearby drivers',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${_secondsElapsed}s',
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
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ColorConstant.moyoOrangeFade,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: ColorConstant.moyoGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Vijay Nagar Square',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: ColorConstant.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: ColorConstant.moyoOrange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'C21 Mall, Vijay Nagar',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: ColorConstant.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Your offer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '₹180',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: ColorConstant.moyoOrange,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: const [
                                Text(
                                  'Cheif',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '>',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Cook',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstant.scaffoldGray,
                              foregroundColor: ColorConstant.onSurface,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Cancel Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).padding.bottom),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AcceptedBid {
  final String serviceId;
  final String bidId;
  final String amount;
  final ServiceData service;
  final ProviderData provider;
  final String acceptedAt;

  AcceptedBid({
    required this.serviceId,
    required this.bidId,
    required this.amount,
    required this.service,
    required this.provider,
    required this.acceptedAt,
  });

  factory AcceptedBid.fromJson(Map<String, dynamic> json) {
    return AcceptedBid(
      serviceId: json['service_id'] ?? '',
      bidId: json['bid_id'] ?? '',
      amount: json['amount'] ?? '',
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

  ServiceData({
    required this.id,
    required this.title,
    required this.category,
    required this.service,
    required this.description,
    required this.location,
  });

  factory ServiceData.fromJson(Map<String, dynamic> json) {
    return ServiceData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      service: json['service'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
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

class Provider {
  final String id;
  final String name;
  final double rating;
  final double distance;
  final LatLng location;

  Provider({
    required this.id,
    required this.name,
    required this.rating,
    required this.distance,
    required this.location,
  });
}
