import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import 'service_controller.dart';

class ServiceListPage extends GetView<ServiceController> {
  const ServiceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.services.isEmpty) {
          return _EmptyState(theme);
        }

        return RefreshIndicator(
          onRefresh: controller.loadServices,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.services.length,
            itemBuilder: (context, index) {
              final service = controller.services[index];

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Get.toNamed(
                    AppRoutes.SERVICE_DETAIL,
                    arguments: service.id,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.secondary,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: cs.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Status icon
                      _StatusIconModern(service.status),

                      const SizedBox(width: 14),

                      /// Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Description
                            Text(
                              "Service "+service.id.toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 6),

                            /// Meta info
                            Text(
                              'Booked • ${_formatDate(service.createdAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 10),

                            /// Status chip
                            
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),
                      _StatusChipModern(service.status),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year}';
  }
}

/// --------------------
/// Empty State
/// --------------------
class _EmptyState extends StatelessWidget {
  final ThemeData theme;

  const _EmptyState(this.theme);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build_outlined,
            size: 64,
            color: theme.iconTheme.color?.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No services booked yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your booked services will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color:
                  theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// --------------------
/// Modern Status Icon
/// --------------------
class _StatusIconModern extends StatelessWidget {
  final String status;

  const _StatusIconModern(this.status);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    late Color color;
    late IconData icon;

    switch (status) {
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'assigned':
        color = Colors.blue;
        icon = Icons.assignment_turned_in_outlined;
        break;
      case 'awaiting_otp':
        color = Colors.orange;
        icon = Icons.sms_outlined;
        break;
      case 'cancelled':
        color = const Color.fromARGB(255, 255, 0, 0);
        icon = Icons.no_backpack_outlined;
        break;
      default:
        color = cs.primary;
        icon = Icons.hourglass_bottom_outlined;
    }

    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color),
    );
  }
}

/// --------------------
/// Modern Status Chip
/// --------------------
class _StatusChipModern extends StatelessWidget {
  final String status;

  const _StatusChipModern(this.status);

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;

    switch (status) {
      case 'completed':
        label = 'Completed';
        color = Colors.green;
        break;
      case 'assigned':
        label = 'Assigned';
        color = Colors.blue;
        break;
      case 'awaiting_otp':
        label = 'Awaiting OTP';
        color = Colors.orange;
        break;
      case 'cancelled':
        label = 'Cancelled';
        color = const Color.fromARGB(255, 255, 0, 0);
        break;
      default:
        label = 'Pending';
        color = Colors.grey;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
