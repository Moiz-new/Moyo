import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../constants/colorConstant/color_constant.dart';
import '../Address/MyAddressProvider.dart';

class UserLocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const UserLocationPickerScreen({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
  }) : super(key: key);

  @override
  State<UserLocationPickerScreen> createState() =>
      _UserLocationPickerScreenState();
}

class _UserLocationPickerScreenState extends State<UserLocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _address = '';
  bool _isLoadingAddress = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // For suggestions
  List<Map<String, dynamic>> _searchSuggestions = [];
  bool _showSuggestions = false;
  bool _isSearching = false;
  String? _debounceTimer;

  // For saved addresses
  bool _showSavedAddresses = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = LatLng(
      widget.initialLatitude ?? 22.7196,
      widget.initialLongitude ?? 75.8577,
    );
    _getAddressFromLatLng(_selectedLocation!);

    // Listen to search field changes with debounce
    _searchController.addListener(_onSearchChanged);

    // Fetch saved addresses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyAddressProvider>().fetchAddresses();
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // Cancel previous timer if exists
    if (_debounceTimer != null) {
      // Simple debounce implementation
      Future.delayed(Duration.zero, () {});
    }

    if (query.length >= 3) {
      // Wait 500ms before searching
      Future.delayed(Duration(milliseconds: 500), () {
        if (_searchController.text.trim() == query) {
          _searchLocationSuggestions(query);
        }
      });
    } else {
      setState(() {
        _showSuggestions = false;
        _searchSuggestions.clear();
      });
    }
  }

  Future<void> _searchLocationSuggestions(String query) async {
    if (query.isEmpty || query.length < 3) return;

    setState(() {
      _isSearching = true;
      _showSuggestions = true;
    });

    try {
      // Search for locations
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty && mounted) {
        List<Map<String, dynamic>> suggestions = [];

        // Process up to 5 locations
        for (var location in locations.take(5)) {
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              location.latitude,
              location.longitude,
            );

            if (placemarks.isNotEmpty) {
              final place = placemarks.first;
              String address = _formatAddress(place);

              suggestions.add({
                'address': address,
                'latitude': location.latitude,
                'longitude': location.longitude,
              });
            }
          } catch (e) {
            debugPrint('Error getting placemark: $e');
          }
        }

        if (mounted) {
          setState(() {
            _searchSuggestions = suggestions;
            _isSearching = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _searchSuggestions = [];
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      if (mounted) {
        setState(() {
          _searchSuggestions = [];
          _isSearching = false;
          _showSuggestions = false;
        });
      }
    }
  }

  String _formatAddress(Placemark place) {
    List<String> parts = [];
    if (place.street?.isNotEmpty == true) parts.add(place.street!);
    if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
    if (place.administrativeArea?.isNotEmpty == true)
      parts.add(place.administrativeArea!);
    if (place.country?.isNotEmpty == true) parts.add(place.country!);
    return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    final newPosition = LatLng(suggestion['latitude'], suggestion['longitude']);

    // Close suggestions immediately
    setState(() {
      _selectedLocation = newPosition;
      _address = suggestion['address'];
      _showSuggestions = false;
      _searchSuggestions.clear();
      _searchController.text = suggestion['address'];
    });

    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    // Animate camera
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPosition, 15));
  }

  void _selectSavedAddress(AddressModel address) {
    final newPosition = LatLng(
      double.parse(address.latitude),
      double.parse(address.longitude),
    );

    setState(() {
      _selectedLocation = newPosition;
      _address = address.fullAddress;
      _showSavedAddresses = false;
    });

    // Animate camera
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPosition, 15));

    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _showSuggestions = false;
      _searchSuggestions.clear();
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _address = _formatAddress(place);
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      setState(() {
        _address = 'Lat: ${position.latitude.toStringAsFixed(4)}, '
            'Lon: ${position.longitude.toStringAsFixed(4)}';
      });
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      final newPosition = LatLng(position.latitude, position.longitude);

      setState(() => _selectedLocation = newPosition);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPosition, 15),
      );

      await _getAddressFromLatLng(newPosition);
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Close suggestions when tapping outside
        if (_showSuggestions) {
          setState(() => _showSuggestions = false);
        }
        if (_showSavedAddresses) {
          setState(() => _showSavedAddresses = false);
        }
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Select Location'),
          backgroundColor: ColorConstant.appColor,
          foregroundColor: ColorConstant.white,
        ),
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation!,
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onTap: (position) async {
                setState(() {
                  _selectedLocation = position;
                  _showSuggestions = false;
                  _showSavedAddresses = false;
                });
                FocusScope.of(context).unfocus();
                await _getAddressFromLatLng(position);
              },
              markers: _selectedLocation != null
                  ? {
                Marker(
                  markerId: MarkerId('selected'),
                  position: _selectedLocation!,
                  draggable: true,
                  onDragEnd: (position) async {
                    setState(() => _selectedLocation = position);
                    await _getAddressFromLatLng(position);
                  },
                ),
              }
                  : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
            ),

            // Search bar with suggestions
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search input
                        Container(
                          decoration: BoxDecoration(
                            color: ColorConstant.white,
                            borderRadius: _showSuggestions &&
                                _searchSuggestions.isNotEmpty
                                ? BorderRadius.vertical(
                              top: Radius.circular(12),
                            )
                                : BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 16),
                              Icon(Icons.search, color: Colors.grey[600]),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  decoration: InputDecoration(
                                    hintText: 'Search location...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                  onTap: () {
                                    if (_searchController.text.length >= 3 &&
                                        _searchSuggestions.isNotEmpty) {
                                      setState(() => _showSuggestions = true);
                                    }
                                    setState(() => _showSavedAddresses = false);
                                  },
                                ),
                              ),
                              if (_isSearching)
                                Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        ColorConstant.moyoOrange,
                                      ),
                                    ),
                                  ),
                                )
                              else if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: _clearSearch,
                                ),
                              SizedBox(width: 8),
                            ],
                          ),
                        ),

                        // Suggestions list
                        if (_showSuggestions && _searchSuggestions.isNotEmpty)
                          Container(
                            constraints: BoxConstraints(maxHeight: 250),
                            decoration: BoxDecoration(
                              color: ColorConstant.white,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _searchSuggestions.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                thickness: 0.5,
                                color: Colors.grey[300],
                              ),
                              itemBuilder: (context, index) {
                                final suggestion = _searchSuggestions[index];
                                return InkWell(
                                  onTap: () => _selectSuggestion(suggestion),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 20,
                                          color: ColorConstant.moyoOrange,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            suggestion['address'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: ColorConstant.onSurface,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.north_west,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        // No results message
                        if (_showSuggestions &&
                            _searchSuggestions.isEmpty &&
                            !_isSearching &&
                            _searchController.text.length >= 3)
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ColorConstant.white,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search_off, color: Colors.grey),
                                SizedBox(width: 12),
                                Text(
                                  'No locations found',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Saved Addresses Button
            Positioned(
              right: 16,
              bottom: 230,
              child: FloatingActionButton(
                heroTag: 'saved_addresses',
                mini: true,
                backgroundColor: ColorConstant.white,
                child: Icon(Icons.bookmark, color: ColorConstant.moyoOrange),
                onPressed: () {
                  setState(() {
                    _showSavedAddresses = !_showSavedAddresses;
                    _showSuggestions = false;
                  });
                  FocusScope.of(context).unfocus();
                },
              ),
            ),

            // Current location button
            Positioned(
              right: 16,
              bottom: 180,
              child: FloatingActionButton(
                heroTag: 'current_location',
                mini: true,
                backgroundColor: ColorConstant.white,
                child: Icon(Icons.my_location, color: ColorConstant.moyoOrange),
                onPressed: () {
                  setState(() {
                    _showSuggestions = false;
                    _showSavedAddresses = false;
                  });
                  _getCurrentLocation();
                },
              ),
            ),

            // Saved Addresses Panel
            if (_showSavedAddresses)
              Positioned(
                top: 80,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 400),
                    decoration: BoxDecoration(
                      color: ColorConstant.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ColorConstant.moyoOrangeFade,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bookmark,
                                color: ColorConstant.moyoOrange,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Saved Addresses',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: ColorConstant.onSurface,
                                ),
                              ),
                              Spacer(),
                              InkWell(
                                onTap: () {
                                  setState(() => _showSavedAddresses = false);
                                },
                                child: Icon(
                                  Icons.close,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Address List
                        Flexible(
                          child: Consumer<MyAddressProvider>(
                            builder: (context, provider, child) {
                              if (provider.isLoading) {
                                return Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: CircularProgressIndicator(
                                      color: ColorConstant.moyoOrange,
                                    ),
                                  ),
                                );
                              }

                              if (provider.addresses.isEmpty) {
                                return Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_off,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No saved addresses',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.symmetric(vertical: 8),
                                itemCount: provider.addresses.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Colors.grey[300],
                                ),
                                itemBuilder: (context, index) {
                                  final address = provider.addresses[index];
                                  return InkWell(
                                    onTap: () => _selectSavedAddress(address),
                                    child: Container(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: address.isDefault
                                                  ? ColorConstant.moyoOrange
                                                  .withOpacity(0.2)
                                                  : ColorConstant
                                                  .moyoOrangeFade,
                                              borderRadius:
                                              BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              address.isDefault
                                                  ? Icons.home
                                                  : Icons.home_outlined,
                                              color: ColorConstant.moyoOrange,
                                              size: 20,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                if (address.isDefault)
                                                  Container(
                                                    margin: EdgeInsets.only(
                                                        bottom: 4),
                                                    padding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: ColorConstant
                                                          .moyoGreen,
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          12),
                                                    ),
                                                    child: Text(
                                                      'Primary',
                                                      style: TextStyle(
                                                        color: ColorConstant
                                                            .white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                        FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                Text(
                                                  address.fullAddress,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                    ColorConstant.onSurface,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                  TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Pincode: ${address.pincode}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey[400],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Address card
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: ColorConstant.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: ColorConstant.moyoOrange,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Selected Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorConstant.onSurface,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _isLoadingAddress
                        ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ColorConstant.moyoOrange,
                          ),
                        ),
                      ),
                    )
                        : Text(
                      _address,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_selectedLocation != null) {
                            Navigator.pop(context, {
                              'latitude': _selectedLocation!.latitude,
                              'longitude': _selectedLocation!.longitude,
                              'address': _address,
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstant.moyoOrange,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Confirm Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorConstant.white,
                          ),
                        ),
                      ),
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

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}