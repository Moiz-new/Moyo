import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../widgets/user_service_list_card.dart';
import 'ServiceModel.dart';
import 'ServiceProvider.dart';

class UserPendingService extends StatefulWidget {
  const UserPendingService({super.key});

  @override
  State<UserPendingService> createState() => _UserPendingServiceState();
}

class _UserPendingServiceState extends State<UserPendingService>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndFetch();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will refresh when the tab becomes visible again
    if (mounted) {
      _initializeAndFetch();
    }
  }

  Future<void> _initializeAndFetch() async {
    final provider = context.read<ServiceProvider>();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId != null) {
      // Initialize NATS subscription
      await provider.initializeServiceNatsSubscription(userId);
    }

    // Always fetch fresh services
    await provider.fetchServices();
  }

  String _getDuration(ServiceModel service) {
    if (service.durationValue != null && service.durationUnit != null) {
      return '${service.durationValue} ${service.durationUnit}${service.durationValue! > 1 ? 's' : ''}';
    } else if (service.serviceDays != null) {
      return '${service.serviceDays} day${service.serviceDays! > 1 ? 's' : ''}';
    }
    return 'N/A';
  }

  String _getPriceBy(ServiceModel service) {
    if (service.bids.isNotEmpty) {
      return service.bids.first.amount.toStringAsFixed(0);
    }
    return service.budget;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Consumer<ServiceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.filteredServices.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.filteredServices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading services',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(provider.error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.refreshServices(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.filteredServices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No closed or pending services found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refreshServices(),
          child: ListView.builder(
            itemCount: provider.filteredServices.length,
            itemBuilder: (context, index) {
              final service = provider.filteredServices[index];

              return UserServiceListCard(
                category: service.category,
                subCategory: service.service,
                date: service.createdAtFormatted,
                dp: "https://ui-avatars.com/api/?name=${service.category}&background=random",
                price: _getPriceBy(service),
                duration: _getDuration(service),
                priceBy: _getPriceBy(service),
                providerCount: int.tryParse(service.totalBids) ?? 0,
                status: service.status,
                onPress: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    '/UserServiceDetailsScreen',
                    arguments: service,
                  );

                  // ✅ CHANGE: Refresh when booking is successful
                  if (result == true && mounted) {
                    // Show loading indicator
                    provider.refreshServices();

                    // Show success message
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Service list updated'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}