import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../widgets/provider_service_list_card.dart';
import '../../provider_service_details_screen.dart';
import 'ProviderBidProvider.dart';

class ProviderBidService extends StatefulWidget {
  const ProviderBidService({super.key});

  @override
  State<ProviderBidService> createState() => _ProviderBidServiceState();
}

class _ProviderBidServiceState extends State<ProviderBidService> {
  @override
  void initState() {
    super.initState();
    // Initialize subscription when screen loads
    // NATS is already connected from app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only initialize if not already initialized
      final provider = context.read<ProviderBidProvider>();
      if (!provider.isConnected || provider.providerId == null) {
        provider.initialize();
      }
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:$minute $period';
      }
      return time;
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProviderBidProvider>(
        builder: (context, bidProvider, child) {
          // Show loading indicator
          if (bidProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Setting up service listener...'),
                ],
              ),
            );
          }

          // Show error message
          if (bidProvider.error != null && !bidProvider.isConnected) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      bidProvider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => bidProvider.retry(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Connection'),
                  ),
                ],
              ),
            );
          }

          // Show empty state
          if (bidProvider.bids.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No service requests yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You will see new requests here automatically',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  if (bidProvider.isConnected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Listening for requests...',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }

          // Show list of service requests
          return RefreshIndicator(
            onRefresh: () async {
              await bidProvider.refresh();
            },
            child: ListView.builder(
              itemCount: bidProvider.bids.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final bid = bidProvider.bids[index];

                return ProviderServiceListCard(
                  category: bid.category,
                  subCategory: bid.service,
                  date: _formatDate(bid.scheduleDate),
                  dp: "https://picsum.photos/200/200?random=$index",
                  price: bid.budget.toStringAsFixed(2),
                  duration: bid.durationDisplay,
                  priceBy: bid.tenure == 'one_time' ? 'One Time' : bid.tenure,
                  providerCount: null,
                  status: "No status",
                  onPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProviderServiceDetailsScreen(serviceId: bid.id),
                      ),
                    ).then((_) {
                      // This runs when user comes back from ProviderServiceDetailsScreen
                      final provider = context.read<ProviderBidProvider>();
                      if (!provider.isConnected ||
                          provider.providerId == null) {
                        provider.initialize();
                      }
                    });
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
