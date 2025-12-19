import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'service_detail_controller.dart';
import '../../routes/app_routes.dart';

class ServiceDetailPage extends GetView<ServiceDetailController> {
  const ServiceDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Details'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final service = controller.service.value;
        if (service == null) {
          return const Center(child: Text('Service not found'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// --------------------
            /// STATUS HEADER
            /// --------------------
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: cs.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _StatusIconModern(service.status)
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Service #${service.id}",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          service.description,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(service.status),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// --------------------
            /// SERVICE INFO
            /// --------------------
            _ModernSection(
              title: 'Service Information',
              children: [
                _InfoTile(
                  icon: Icons.settings_outlined,
                  label: 'Visit Type',
                  value: service.visitType,
                ),
                _InfoTile(
                  icon: Icons.category_outlined,
                  label: 'Service Type',
                  value: service.serviceType.toUpperCase(),
                ),
                _InfoTile(
                  icon: Icons.report_problem_outlined,
                  label: 'Complaint',
                  value: service.description,
                ),
                _InfoTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Booked Date',
                  value: _formatDate(service.createdAt),
                ),
                _InfoTile(
                  icon: Icons.event_outlined,
                  label: 'Preferred Date',
                  value: service.preferredDate != null
                      ? _formatDate(service.preferredDate!)
                      : 'Not specified',
                ),
              ],
            ),

            /// --------------------
            /// SCHEDULE
            /// --------------------
            if (service.scheduledAt != null ||
                service.assignedToName != null) ...[
              const SizedBox(height: 20),
              _ModernSection(
                title: 'Schedule',
                children: [
                  if (service.scheduledAt != null)
                    _InfoTile(
                      icon: Icons.schedule_outlined,
                      label: 'Service On',
                      value:
                          _formatDate(service.scheduledAt!),
                    ),
                  if (service.assignedToName != null)
                    _InfoTile(
                      icon: Icons.person_outline,
                      label: 'Assigned Staff Name',
                      value: service.assignedToName!,
                    ),
                  if (service.assignedToPhone != null)
                    _InfoTile(
                      icon: Icons.call_outlined,
                      label: 'Assigned Staff Phone',
                      value: service.assignedToPhone!,
                    ),
                ],
              ),
            ],

            /// --------------------
            /// SERVICE ENTRIES
            /// --------------------
            
            if (service.status =="completed" && service.entries.isNotEmpty) ...[
              const SizedBox(height: 20),
              _ModernSection(
                title: 'Service Entry',
                children: [
                      _InfoTile(
                        icon: Icons.report_problem_outlined,
                        label: 'Actual Complaint',
                        value: service.entries.last.actualComplaint,
                      ),

                      _InfoTile(
                        icon: Icons.build_outlined,
                        label: 'Work Done',
                        value: service.entries.last.workDetail,
                      ),

                      if (service.entries.last.amountCharged != null)
                        _InfoTile(
                          icon: Icons.currency_rupee,
                          label: 'Amount Charged',
                          value: '₹${service.entries.last.amountCharged}',
                        ),

                      _InfoTile(
                        icon: Icons.event,
                        label: 'Service Date',
                        value: _formatDate(service.entries.last.createdAt),
                      ),
                ],
              ),
            ],

            /// --------------------
            /// FEEDBACK MESSAGE
            /// --------------------
            
            if (service.hasFeedback) ...[
                SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.secondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color:cs.primary.withOpacity(0.2))
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Feedback',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(
                          service.feedbackRating ?? 0,
                          (_) => const Icon(Icons.star, color: Colors.amber, size: 18),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(service.feedbackComment ?? ''),
                    ],
                  ),
                ),
              ],

            /// --------------------
            /// COMPLETED MESSAGE
            /// --------------------
            if (service.status == 'completed') ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Service completed successfully.\nThank you for choosing VST Maarketing.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              /// --------------------
              /// GIVE FEEDBACK BUTTON
              /// --------------------
              if (service.status == 'completed' && !service.hasFeedback)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Give Feedback'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Get.toNamed(
                      AppRoutes.FEEDBACK,
                      arguments: service.id,
                    );
                  },
                )
              ),
              
            ],
          ],
        );
      }),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}-${date.month}-${date.year}';
}


class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;

    switch (status) {
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        break;
      case 'assigned':
        color = Colors.blue;
        label = 'Assigned';
        break;
      case 'awaiting_otp':
        color = Colors.orange;
        label = 'Awaiting OTP';
        break;
      case 'cancelled':
        label = 'Cancelled';
        color = const Color.fromARGB(255, 255, 0, 0);
        break;
      default:
        color = Colors.grey;
        label = 'Pending';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}


class _ModernSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ModernSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.secondary,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cs.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}


class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15)
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    ),
    );
  }
}

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
        color = cs.secondary;
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