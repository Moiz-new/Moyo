import 'package:first_flutter/screens/user_screens/Address/AddAddressScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colorConstant/color_constant.dart';
import 'MyAddressProvider.dart';
import 'EditAddressScreen.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({Key? key}) : super(key: key);

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyAddressProvider>().fetchAddresses();
    });
  }

  void _showSetPrimaryDialog(BuildContext context, AddressModel address) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Set as Primary Address',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ColorConstant.black,
          ),
        ),
        content: Text(
          'Do you want to set this as your primary address?',
          style: TextStyle(fontSize: 14, color: ColorConstant.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await context
                  .read<MyAddressProvider>()
                  .setPrimaryAddress(address.id);

              if (success) {
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update primary address'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstant.moyoOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Yes, Set Primary',
              style: TextStyle(
                color: ColorConstant.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.white,
      appBar: AppBar(
        backgroundColor: ColorConstant.moyoOrange,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorConstant.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Addresses',
          style: TextStyle(
            color: ColorConstant.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<MyAddressProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Add new Address Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddAddressScreen(),
                      ),
                    );

                    if (result != null) {
                      provider.fetchAddresses();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: ColorConstant.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ColorConstant.moyoOrange,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: ColorConstant.moyoOrange,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Add new Address',
                          style: TextStyle(
                            color: ColorConstant.moyoOrange,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // All Saved Addresses Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'All Saved Addresses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColorConstant.black,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Addresses List
              Expanded(
                child: provider.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: ColorConstant.moyoOrange,
                        ),
                      )
                    : provider.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              provider.errorMessage!,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => provider.fetchAddresses(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorConstant.moyoOrange,
                              ),
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : provider.addresses.isEmpty
                    ? Center(
                        child: Text(
                          'No addresses found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.addresses.length,
                        itemBuilder: (context, index) {
                          return _buildAddressCard(
                            context,
                            provider.addresses[index],
                            provider.isSettingPrimary,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    AddressModel address,
    bool isProcessing,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstant.white,
        borderRadius: BorderRadius.circular(12),
        border: address.isDefault
            ? Border.all(color: ColorConstant.moyoOrange, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: address.isDefault
                      ? ColorConstant.moyoOrange.withOpacity(0.2)
                      : ColorConstant.moyoOrangeFade,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  address.isDefault ? Icons.home : Icons.home_outlined,
                  color: ColorConstant.moyoOrange,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.fullAddress,
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorConstant.onSurface,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'PinCode : ${address.pincode}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorConstant.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Primary Badge
          if (address.isDefault)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: ColorConstant.moyoGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: ColorConstant.white,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Primary',
                    style: TextStyle(
                      color: ColorConstant.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 12),

          // Action Buttons Row
          Row(
            children: [
              // Edit Button
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditAddressScreen(
                          addressId: address.id,
                          addressData: {
                            'type': address.type,
                            'address_line1': address.addressLine1,
                            'address_line2': address.addressLine2,
                            'landmark': address.landmark,
                            'city': address.city,
                            'state': address.state,
                            'pincode': address.pincode,
                            'latitude': address.latitude,
                            'longitude': address.longitude,
                            'country': address.country,
                            'is_default': address.isDefault,
                          },
                        ),
                      ),
                    );

                    if (result == true) {
                      context.read<MyAddressProvider>().fetchAddresses();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ColorConstant.moyoOrange,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: ColorConstant.moyoOrange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: ColorConstant.moyoOrange,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Set Primary Button (only show if not already primary)
              if (!address.isDefault) ...[
                SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: isProcessing
                        ? null
                        : () => _showSetPrimaryDialog(context, address),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: ColorConstant.moyoOrange,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isProcessing)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ColorConstant.white,
                              ),
                            )
                          else ...[
                            Icon(
                              Icons.star_outline,
                              color: ColorConstant.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Set Primary',
                              style: TextStyle(
                                color: ColorConstant.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
