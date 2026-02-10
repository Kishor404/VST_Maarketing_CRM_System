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

    return RefreshIndicator(
      onRefresh: controller.loadJobCards,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (_, i) {
          return _JobCardTile(
            jobCard: list[i],
            reinstallMode: reinstallMode,
          );
        },
      ),
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
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  jobCard.partName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _statusChip(jobCard.status),
              ],
            ),

            const SizedBox(height: 8),

            /// DETAILS
            Text(jobCard.details),

            const SizedBox(height: 8),

            /// STAFF INFO
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

            /// IMAGE
            if (jobCard.fullImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  jobCard.fullImageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            /// ======================
            /// REINSTALL FLOW
            /// ======================
            if (reinstallMode && jobCard.isRepairCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [

                    /// REQUEST OTP BUTTON
                    Obx(() => ElevatedButton.icon(
                          icon: controller.reinstallLoading.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock),
                          label: Text(
                            controller.reinstallLoading.value
                                ? "Requesting OTP..."
                                : "Request Reinstall OTP",
                          ),
                          onPressed: controller.reinstallLoading.value
                              ? null
                              : () async {

                                  /// STEP 1 → REQUEST OTP
                                  await controller.requestReinstallOtp(
                                    jobCard.id,
                                  );

                                  /// STEP 2 → ASK USER OTP
                                  final otp = await _askOtp(context);
                                  if (otp == null || otp.isEmpty) return;

                                  /// STEP 3 → VERIFY OTP
                                  controller.verifyReinstallOtp(
                                    jobCard: jobCard,
                                    otp: otp,
                                  );
                                },
                        )),

                    /// DEV OTP DISPLAY
                    Obx(() {
                      if (controller.devOtp.value.isEmpty) {
                        return const SizedBox();
                      }

                      return Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bug_report,
                                color: Colors.orange),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "DEV OTP: ${controller.devOtp.value}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// STATUS CHIP
  Widget _statusChip(String status) {
    Color color;

    switch (status) {
      case "repair_completed":
        color = Colors.orange;
        break;
      case "reinstalled":
        color = Colors.green;
        break;
      case "received_office":
        color = Colors.blue;
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

  /// OTP DIALOG
  Future<String?> _askOtp(BuildContext context) async {
    final ctrl = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter OTP"),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            hintText: "Enter 4 digit OTP",
            counterText: "",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: ctrl.text),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}
