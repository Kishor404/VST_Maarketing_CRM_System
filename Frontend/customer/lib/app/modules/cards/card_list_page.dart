import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../data/models/card_model.dart';
import 'card_controller.dart';
class CardListPage extends GetView<CardController> {
  const CardListPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Service Cards'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.cards.isEmpty) {
          return const _EmptyCardState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.cards.length,
          itemBuilder: (context, index) {
            return _ModernCardTile(card: controller.cards[index]);
          },
        );
      }),
    );
  }
}


class _ModernCardTile extends StatelessWidget {
  final CardModel card;

  const _ModernCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final warrantyActive = card.isWarrantyActive;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Get.toNamed(AppRoutes.CARD_DETAIL, arguments: card.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.secondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cs.primary.withOpacity(0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Icon tile
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: card.isOtherMachine
                        ? Colors.orange.withOpacity(0.12)
                        : cs.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    card.isOtherMachine
                        ? Icons.devices_other_outlined
                        : Icons.water_drop_outlined,
                    color: card.isOtherMachine
                        ? Colors.orange
                        : cs.primary,
                  ),
                ),

                const SizedBox(width: 14),

                /// Title + address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${card.model} - ${card.id}",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),

                /// Warranty badge
                _WarrantyBadgeModern(active: warrantyActive),
              ],
            ),

            const SizedBox(height: 12),

            /// Location + type
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color:
                      theme.iconTheme.color?.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '${card.city ?? ''} ${card.postalCode ?? ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withOpacity(0.6),
                  ),
                ),
                const Spacer(),
                Text(
                  card.cardTypeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            if (card.warrantyEndDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Warranty till ${_formatDate(card.warrantyEndDate!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                      ?.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }
}


class _WarrantyBadgeModern extends StatelessWidget {
  final bool active;

  const _WarrantyBadgeModern({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
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


class _EmptyCardState extends StatelessWidget {
  const _EmptyCardState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_outlined,
              size: 64,
              color: theme.iconTheme.color?.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Service Cards',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your service cards will appear here once added.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color
                    ?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


