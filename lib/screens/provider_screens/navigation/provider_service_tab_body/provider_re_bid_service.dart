import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../widgets/provider_service_list_card.dart';
import '../../confirm_provider_service_details_screen.dart';

class ProviderReBidService extends StatefulWidget {
  const ProviderReBidService({super.key});

  @override
  State<ProviderReBidService> createState() => _ProviderReBidServiceState();
}

class _ProviderReBidServiceState extends State<ProviderReBidService> {
  List<dynamic> services = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  Future<void> fetchServices() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('provider_auth_token');

      if (token == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Authentication token not found';
        });
        return;
      }

      // Make API call
      final response = await http.get(
        Uri.parse('$base_url/bid/api/service/open-services'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          setState(() {
            services = data['data'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = data['message'] ?? 'Failed to load services';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${_getMonthName(date.month)} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String getDurationText(dynamic service) {
    final durationValue = service['duration_value'];
    final durationUnit = service['duration_unit'];

    if (durationValue != null && durationUnit != null) {
      return '$durationValue ${durationUnit}${durationValue > 1 ? 's' : ''}';
    }
    return 'N/A';
  }

  String getStatusText(String? rebidStatus, String? status) {
    if (rebidStatus != null && rebidStatus.isNotEmpty) {
      return rebidStatus;
    }
    return status ?? 'open';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchServices,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'No rebid services available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchServices,
      child: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];

          return ProviderServiceListCard(
            category: service['category'] ?? 'N/A',
            subCategory: service['service'] ?? 'N/A',
            date: formatDate(service['created_at']),
            dp: "https://picsum.photos/200/200",
            price: service['bid_amount'] ?? service['budget'] ?? '0',
            duration: getDurationText(service),
            priceBy: service['service_mode'] == 'hrs' ? 'Hourly' : 'Fixed',
            providerCount: 0,
            // This data is not in the API response
            status: getStatusText(service['rebid_status'], service['status']),
            onPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfirmProviderServiceDetailsScreen(
                    serviceId: service['id'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
