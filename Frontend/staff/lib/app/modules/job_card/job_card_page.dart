import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'job_card_controller.dart';
import '../../data/models/job_card_model.dart';

class JobCardPage extends GetView<JobCardController> {
  const JobCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Job Cards"),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: "My Job Cards"),
              Tab(text: "Reinstall"),
            ],
          ),
        ),

        body: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: [
              _buildList(
                context,
                controller.myJobCards,
                emptyText: "No Job Cards Created",
              ),
              _buildList(
                context,
                controller.reinstallJobCards,
                emptyText: "No Reinstall Jobs",
                reinstallMode: true,
              ),
            ],
          );
        }),
      ),
    );
  }

  /// =====================================================
  /// Job Card List Builder
  /// =====================================================
  Widget _buildList(
    BuildContext context,
    List<JobCardModel> items, {
    required String emptyText,
    bool reinstallMode = false,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final jc = items[index];
        return _JobCardTile(
          jobCard: jc,
          reinstallMode: reinstallMode,
        );
      },
    );
  }
}

/// =====================================================
/// Job Card Tile
/// =====================================================
class _JobCardTile extends StatelessWidget {
  final JobCardModel jobCard;
  final bool reinstallMode;

  const _JobCardTile({
    required this.jobCard,
    this.reinstallMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    String statusLabel;

    switch (jobCard.status) {
      case "repair_completed":
        statusColor = Colors.orange;
        statusLabel = "Repair Completed";
        break;
      case "reinstalled":
        statusColor = Colors.green;
        statusLabel = "Reinstalled";
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = "Pending";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  jobCard.partName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 8),

            /// Details
            Text(
              jobCard.details,
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 8),

            /// Meta
            if (jobCard.staffName != null)
              Text(
                "Created by: ${jobCard.staffName}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),

            if (jobCard.reinstallStaffName != null)
              Text(
                "Reinstall Staff: ${jobCard.reinstallStaffName}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),

            const SizedBox(height: 10),

            /// Image
            if (jobCard.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  jobCard.fullImageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            /// Reinstall CTA
            if (reinstallMode && jobCard.isRepairCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.build),
                  label: const Text("Reinstall Part"),
                  onPressed: () {
                    // 🔜 navigate to reinstall flow
                  },
                ),
              )
          ],
        ),
      ),
    );
  }
}
