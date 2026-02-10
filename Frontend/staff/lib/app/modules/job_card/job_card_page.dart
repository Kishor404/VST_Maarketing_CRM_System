import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'job_card_controller.dart';
import '../../data/models/job_card_model.dart';

class JobCardPage extends GetView<JobCardController> {
  const JobCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Slightly off-white background
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            /// ============================
            /// CUSTOM TOP TAB BAR (Preserved)
            /// ============================
            Material(
              color: theme.colorScheme.surface,
              elevation: 2, // Slight elevation for depth
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: theme.primaryColor,
                      unselectedLabelColor: Colors.grey[500],
                      indicatorColor: theme.primaryColor,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorWeight: 3,
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      tabs: const [
                        Tab(text: "My Job Cards"),
                        Tab(text: "Reinstall"),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            /// ============================
            /// BODY
            /// ============================
            Expanded(
              child: Obx(() {
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
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<JobCardModel> list, bool reinstallMode) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("No Job Cards Found", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadJobCards,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: list.length,
        itemBuilder: (_, i) => _JobCardTile(jobCard: list[i], reinstallMode: reinstallMode),
      ),
    );
  }
}

class _JobCardTile extends StatelessWidget {
  final JobCardModel jobCard;
  final bool reinstallMode;

  const _JobCardTile({required this.jobCard, required this.reinstallMode});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<JobCardController>();
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 226, 226, 228),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE SECTION
            if (jobCard.fullImageUrl != null)
              Image.network(
                jobCard.fullImageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          jobCard.partName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      _statusChip(jobCard.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    jobCard.details,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  
                  /// INFO ROW
                  Row(
                    children: [
                      if (jobCard.staffName != null)
                        _infoBadge(Icons.person_outline, jobCard.staffName!),
                      const SizedBox(width: 12),
                      if (jobCard.reinstallStaffName != null)
                        _infoBadge(Icons.build_circle_outlined, jobCard.reinstallStaffName!),
                    ],
                  ),

                  /// REINSTALL FLOW
                  if (reinstallMode && jobCard.isRepairCompleted) ...[
                    const Divider(height: 32),
                    Obx(() => ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: controller.reinstallLoading.value
                              ? null
                              : () async {
                                  await controller.requestReinstallOtp(jobCard.id);

                                  final otp = await _askOtp(context);

                                  if (otp != null && otp.isNotEmpty) {
                                    controller.verifyReinstallOtp(
                                      jobCard: jobCard,
                                      otp: otp,
                                    );
                                  }

                                },
                          child: controller.reinstallLoading.value
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text("Request Reinstall OTP", style: TextStyle(fontWeight: FontWeight.bold)),
                        )),

                    /// DEV OTP BANNER
                    // Obx(() {
                    //   if (controller.devOtp.value.isEmpty) return const SizedBox();
                    //   return Container(
                    //     margin: const EdgeInsets.only(top: 12),
                    //     padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    //     decoration: BoxDecoration(
                    //       color: Colors.amber.shade50,
                    //       borderRadius: BorderRadius.circular(12),
                    //       border: Border.all(color: Colors.amber.shade200),
                    //     ),
                    //     child: Row(
                    //       children: [
                    //         const Icon(Icons.terminal, color: Colors.amber, size: 20),
                    //         const SizedBox(width: 8),
                    //         Text(
                    //           "DEV OTP: ${controller.devOtp.value}",
                    //           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    //         ),
                    //       ],
                    //     ),
                    //   );
                    // }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case "repair_completed": color = Colors.orange; break;
      case "reinstalled": color = Colors.green; break;
      case "received_office": color = Colors.blue; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.replaceAll("_", " ").toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<String?> _askOtp(BuildContext context) async {

    final ctrl = TextEditingController();
    final jobController = Get.find<JobCardController>();

    return showDialog<String>(
      context: context,
      builder: (_) => Obx(() => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),

            title: const Text("Verify Reinstallation"),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Text(
                  "Please enter the 4-digit OTP provided to complete the process.",
                ),

                const SizedBox(height: 16),

                /// ⭐ DEV OTP DISPLAY INSIDE POPUP
                if (jobController.devOtp.value.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bug_report,
                            color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "DEV OTP: ${jobController.devOtp.value}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (jobController.devOtp.value.isNotEmpty)
                  const SizedBox(height: 16),

                /// OTP FIELD
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  maxLength: 4,
                  decoration: InputDecoration(
                    hintText: "0000",
                    counterText: "",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),

            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text("Cancel"),
              ),

              ElevatedButton(
                onPressed: () => Get.back(result: ctrl.text),
                child: const Text("Verify"),
              ),
            ],
          )),
    );
  }

}