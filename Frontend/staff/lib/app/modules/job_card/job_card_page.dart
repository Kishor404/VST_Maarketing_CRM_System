import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'job_card_controller.dart';
import '../../data/models/job_card_model.dart';

class JobCardPage extends GetView<JobCardController> {
  const JobCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Job Cards"),
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
              _buildList(controller.myJobCards, false),
              _buildList(controller.reinstallJobCards, true),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildList(List<JobCardModel> list, bool reinstallMode) {
    if (list.isEmpty) {
      return const Center(child: Text("No Job Cards"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (_, i) {
        return _JobCardTile(
          jobCard: list[i],
          reinstallMode: reinstallMode,
        );
      },
    );
  }
}

class _JobCardTile extends StatelessWidget {
  final JobCardModel jobCard;
  final bool reinstallMode;

  const _JobCardTile({
    required this.jobCard,
    required this.reinstallMode,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<JobCardController>();

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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _statusChip(jobCard.status),
              ],
            ),

            const SizedBox(height: 8),
            Text(jobCard.details),

            const SizedBox(height: 8),
            if (jobCard.staffName != null)
              Text("Created by: ${jobCard.staffName}",
                  style: const TextStyle(fontSize: 12)),

            if (jobCard.reinstallStaffName != null)
              Text("Reinstall: ${jobCard.reinstallStaffName}",
                  style: const TextStyle(fontSize: 12)),

            if (jobCard.fullImageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    jobCard.fullImageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            /// Reinstall button
            if (reinstallMode && jobCard.isRepairCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton(
                  child: const Text("Reinstall (OTP)"),
                  onPressed: () async {
                    final otp = await _askOtp(context);
                    if (otp == null) return;

                    controller.reinstallSingle(
                      jobCard: jobCard,
                      otp: otp,
                    );
                  },
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case "repair_completed":
        color = Colors.orange;
        break;
      case "reinstalled":
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status.replaceAll("_", " ")),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color),
    );
  }

  Future<String?> _askOtp(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter OTP"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: controller.text),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}
