import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../data/models/card_model.dart';
import '../../data/models/service_model.dart';
import 'card_controller.dart';

class CardDetailPage extends GetView<CardController> {
  const CardDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final int cardId = Get.arguments as int;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedCard.value == null ||
          controller.selectedCard.value!.id != cardId) {
        controller.loadCardDetail(cardId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Details'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.detailLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final CardModel? card = controller.selectedCard.value;
        if (card == null) {
          return const Center(child: Text('Failed to load card details'));
        }

        final isWarrantyActive = card.isWarrantyActive;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// --------------------
            /// HERO CARD HEADER
            /// --------------------
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.secondary,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: cs.primary.withOpacity(0.06),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: card.isOtherMachine
                          ? Colors.orange.withOpacity(0.12)
                          : cs.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      card.isOtherMachine
                          ? Icons.devices_other_outlined
                          : Icons.water_drop_outlined,
                      color: card.isOtherMachine
                          ? Colors.orange
                          : cs.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${card.model} - ${card.id}",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${card.address}, ${card.city}",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _WarrantyBadgeModern(active: isWarrantyActive),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// --------------------
            /// WARRANTY DETAILS
            /// --------------------
            _Section(
              title: 'Warranty Information',
              children: [
                _InfoRowModern(
                  icon: isWarrantyActive
                      ? Icons.verified_outlined
                      : Icons.warning_amber_rounded,
                  label: 'Status',
                  value: isWarrantyActive ? 'Active' : 'Expired',
                  color:
                      isWarrantyActive ? Colors.green : Colors.orange,
                ),
                if (card.warrantyStartDate != null)
                  _InfoRowModern(
                    icon: Icons.calendar_month_outlined,
                    label: 'Start Date',
                    value: _formatDate(card.warrantyStartDate!),
                  ),
                if (card.warrantyEndDate != null)
                  _InfoRowModern(
                    icon: Icons.event_busy_outlined,
                    label: 'End Date',
                    value: _formatDate(card.warrantyEndDate!),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            /// --------------------
            /// COMPLETED SERVICES
            /// --------------------
            Text(
              'Completed Services',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            Obx(() {
              final List<ServiceModel> services =
                  controller.completedServices;

              if (services.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.secondary,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: cs.primary.withOpacity(0.05),
                    ),
                  ),
                  child: Text(
                    'No completed services for this card yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withOpacity(0.6),
                    ),
                  ),
                );
              }

              return Column(
                children: services.map((service) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.secondary,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: cs.primary.withOpacity(0.05),
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        Get.toNamed(
                          AppRoutes.SERVICE_DETAIL,
                          arguments: service.id,
                        );
                      },
                    child: Row(
                      children: [
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.description.isNotEmpty
                                    ? service.description
                                    : 'Service Completed',
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Type • ${service.serviceType.toUpperCase()}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: theme
                                      .textTheme.bodySmall?.color
                                      ?.withOpacity(0.6),
                                ),
                              ),
                              if (service.scheduledAt != null)
                                Text(
                                  'Date • ${_formatDate(service.scheduledAt!)}',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: theme.textTheme.bodySmall
                                        ?.color
                                        ?.withOpacity(0.6),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                    
                  );
                }).toList(),
              );
            }),
          ],
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }
}


class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({
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
          color: cs.primary.withOpacity(0.06),
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


class _InfoRowModern extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _InfoRowModern({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? theme.iconTheme.color),
          const SizedBox(width: 14),
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _WarrantyBadgeModern extends StatelessWidget {
  final bool active;

  const _WarrantyBadgeModern({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.red;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Expired',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
