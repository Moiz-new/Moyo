import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../widgets/user_service_list_card.dart';
import '../../AssignedandCompleteUserServiceDetailsScreen.dart';
import 'ServiceModel.dart';
import 'ServiceProvider.dart';

class UserOngoingService extends StatefulWidget {
  const UserOngoingService({super.key});

  @override
  State<UserOngoingService> createState() => _UserOngoingServiceState();
}

class _UserOngoingServiceState extends State<UserOngoingService> {
  @override
  void initState() {
    super.initState();
    _initializeNatsForServiceDetails();
  }

  Future<void> _initializeNatsForServiceDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId != null) {
      // Initialize NATS subscription when landing on this screen
      context.read<ServiceProvider>().initializeServiceNatsSubscription(userId);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<ServiceProvider>();
    if (provider.assignedServices.isEmpty && !provider.isLoading) {
      provider.fetchServices();
    }
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
    if (service.serviceMode == 'hrs') return 'Hourly';
    if (service.serviceMode == 'day') return 'Daily';
    return 'Fixed';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
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

        if (provider.assignedServices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No assigned services found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Services will appear here once assigned',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refreshServices(),
          child: ListView.builder(
            itemCount: provider.assignedServices.length,
            itemBuilder: (context, index) {
              final service = provider.assignedServices[index];
              return UserServiceListCard(
                category: service.category,
                subCategory: service.service,
                date: service.createdAtFormatted,
                dp: "https://ui-avatars.com/api/?name=${service.category}&background=random",
                price: service.budget,
                duration: _getDuration(service),
                priceBy: _getPriceBy(service),
                providerCount: int.tryParse(service.totalBids) ?? 0,
                status: service.status,
                onPress: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AssignedandCompleteUserServiceDetailsScreen(
                            serviceId: service.id,
                          ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
