import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'work_controller.dart';
import '../../data/models/service_model.dart';
import '../../routes/app_routes.dart';

class WorkDetailPage extends GetView<WorkController> {
  const WorkDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final int serviceId = Get.arguments as int;
    final theme = Theme.of(context);

    /// Load only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedService.value == null ||
          controller.selectedService.value!.id != serviceId) {
        controller.loadDetail(serviceId);
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Service Details'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.detailLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final ServiceModel? service = controller.selectedService.value;

        if (service == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('Service not found'),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  /// ============================
                  /// Header Section (Status + Complaint)
                  /// ============================
                  _buildHeaderSection(context, service),
                  
                  const SizedBox(height: 24),

                  /// ============================
                  /// Details Grid
                  /// ============================
                  Text(
                    'Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoGrid(context, service),

                  const SizedBox(height: 24),

                  Text(
                    'Address',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAddressCard(context, service),
                  const SizedBox(height: 24),

                  /// ============================
                  /// Timeline Section
                  /// ============================
                  Row(
                    children: [
                      Icon(Icons.history, size: 20, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Activity History',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (service.entries.isEmpty)
                    _buildEmptyState(context)
                  else
                    ...service.entries.asMap().entries.map((entry) {
                      final isLast = entry.key == service.entries.length - 1;
                      final e = entry.value;
                      return _TimelineRow(
                        complaint: e.actualComplaint,
                        work: e.workDetail,
                        amount: e.amountCharged,
                        date: e.createdAt,
                        partsReplaced: e.partsReplaced,
                        isLast: isLast,
                      );
                    }),
                    
                  // extra padding for bottom button
                  const SizedBox(height: 80), 
                ],
              ),
            ),
          ],
        );
      }),
      
      /// ============================
      /// Sticky Bottom Action Bar
      /// ============================
      bottomNavigationBar: Obx(() {
        final service = controller.selectedService.value;
        if (service == null || service.status == 'completed') return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton.icon(
              onPressed: () {
                Get.toNamed(
                  AppRoutes.workComplete,
                  arguments: service.id,
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Complete The Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeaderSection(BuildContext context, ServiceModel service) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VST Service ${service.id}', // Assuming ID exists
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
              _StatusBadge(status: service.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            service.description,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAddressCard(BuildContext context, ServiceModel service) {
    final theme = Theme.of(context);

    final address = service.cardData?.address ?? '';
    final city = service.cardData?.city ?? '';

    final fullAddress = [address, city]
        .where((e) => e.isNotEmpty)
        .join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_outlined,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fullAddress.isNotEmpty
                  ? fullAddress
                  : 'Address not available',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: const Color(0xFF2E3A44),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildInfoGrid(BuildContext context, ServiceModel service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary,),
      ),
      child: Column(
        children: [
          
          Row(
            children: [
              Expanded(child: _DetailItem(label: 'Customer Name', value: service.customerName)),
              Expanded(child: _DetailItem(label: 'Model', value: service.customerPhone)),
            ],
          ),
          Divider(height: 24, color: Colors.grey[300]),
          Row(
            children: [
              Expanded(child: _DetailItem(label: 'Service Type', value: service.serviceType)),
              Expanded(child: _DetailItem(label: 'Visit Type', value: service.visitType)),
            ],
          ),
          Divider(height: 24, color: Colors.grey[300]),
          Row(
            children: [
              Expanded(child: _DetailItem(label: 'Preferred Date', value: service.preferredDate)),
              Expanded(
                child: _DetailItem(
                  label: 'Scheduled At', 
                  value: service.scheduledAt ?? 'Not Scheduled',
                  isHighlighted: service.scheduledAt != null,
                )
              ),
            ],
          ),
          Divider(height: 24, color: Colors.grey[300]),
          Row(
            children: [
              Expanded(child: _DetailItem(label: 'Machine Model', value: service.cardModel)),
              Expanded(child: _DetailItem(label: 'Machine Type', value: service.cardType))
              
            ],
          ),
          
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Text(
        'No history recorded yet.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
      ),
    );
  }
}


/// ============================
/// Helper Widgets
/// ============================

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _DetailItem({
    required this.label, 
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10, 
            letterSpacing: 1, 
            color: const Color(0xFF000000)
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isHighlighted ? theme.primaryColor : const Color(0xFF2E3A44),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color textColor;
    String label;

    switch (status) {
      case 'awaiting_otp':
        color = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        label = 'Awaiting OTP';
        break;
      case 'completed':
        color = Colors.green.shade50;
        textColor = Colors.green.shade800;
        label = 'Completed';
        break;
      default:
        color = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String complaint;
  final String work;
  final String amount;
  final DateTime date;
  final bool isLast;
  final List<String>? partsReplaced;

  const _TimelineRow({
    required this.complaint,
    required this.work,
    required this.amount,
    required this.date,
    this.partsReplaced,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line & Dot
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFF444444),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            complaint,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₹$amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      work,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),

                    if (partsReplaced != null && partsReplaced!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Parts Replaced',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: partsReplaced!
                            .map(
                              (part) => Chip(
                                label: Text(part),
                                backgroundColor:
                                    theme.primaryColor.withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: theme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: const Color(0xFF444444)),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(date),
                          style: TextStyle(fontSize: 12, color: const Color(0xFF444444)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}