import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'work_controller.dart';

class WorkCompletionPage extends GetView<WorkController> {
  const WorkCompletionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = controller.selectedService.value!;
    final partCtrl = TextEditingController();

    // final otpCtrl = TextEditingController();
    // final workCtrl = TextEditingController();
    // final amountCtrl = TextEditingController();

    void _addPart(
      TextEditingController partCtrl,
      WorkController controller,
    ) {
      final part = partCtrl.text.trim();

      if (part.isEmpty) return;

      // 🔥 PREVENT DUPLICATES (HERE)
      if (!controller.partsReplaced.contains(part)) {
        controller.partsReplaced.add(part);
      }

      partCtrl.clear();
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Service"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0, // subtle elevation for the app bar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ============================
            /// 1. Work and Amount Details
            /// ============================
            Text(
              'Service Summary',
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      maxLines: 3,
                      onChanged: (v) => controller.workDetail.value = v,
                      decoration: const InputDecoration(
                        hintText: "Describe the work completed for the customer.",
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (v) => controller.amountCharged.value = v,
                      decoration: InputDecoration(
                        hintText: "Enter final bill amount",
                        prefixText: '₹ ',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            /// ============================
            /// Parts Replaced Section
            /// ============================
            Text(
              'Parts Replaced',
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: partCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Enter part name (e.g. Filter)',
                          ),
                          onSubmitted: (_) {
                            _addPart(partCtrl, controller);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        color: theme.primaryColor,
                        onPressed: () {
                          _addPart(partCtrl, controller);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Obx(() {
                    if (controller.partsReplaced.isEmpty) {
                      return const Text(
                        'No parts added yet.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.partsReplaced
                          .map(
                            (part) => Chip(
                              label: Text(part),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () => controller.partsReplaced.remove(part),
                            ),
                          )
                          .toList(),
                    );
                  }),
                ],
              ),
            ),


            const SizedBox(height: 32),

            /// ============================
            /// 2. OTP Verification Section
            /// ============================
            Text(
              'Customer Verification',
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            
            // Instruction Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_person_outlined, color: theme.primaryColor),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Request OTP to confirm the job completion with the customer.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Customer Phone',
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // +91 (NON EDITABLE)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '+91',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // PHONE INPUT
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      onChanged: (v) {
                        if (RegExp(r'^\d*$').hasMatch(v)) {
                          controller.phone.value = v;
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: '9876543210',
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),


            // OTP Request Button
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton.icon(
                    icon: controller.otpLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(controller.otpLoading.value ? "Requesting..." : "Request OTP"),
                    onPressed: controller.otpLoading.value || controller.phone.value.length != 10
                        ? null
                        : () => controller.requestOtp(service.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                    ),
                  )),
            ),
            const SizedBox(height: 16),

            Obx(() {
              if (controller.devOtp.value.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'DEV OTP: ${controller.devOtp.value}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // OTP Input Field
            TextField(
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: (v) => controller.otp.value = v,
              decoration: const InputDecoration(
                labelText: "Enter OTP",
                counterText: '',
              ),
            ),

            const SizedBox(height: 80), // Space for the floating bottom button
          ],
        ),
      ),
      
      /// ============================
      /// 3. Sticky Bottom Action
      /// ============================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
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
          child: Obx(() {
            final isFormValid =
                controller.workDetail.value.isNotEmpty &&
                controller.amountCharged.value.isNotEmpty &&
                controller.otp.value.length == 4;

            return ElevatedButton.icon(
              onPressed: (!isFormValid || controller.otpLoading.value)
                  ? null
                  : () {
                      controller.completeService(
                        serviceId: service.id,
                        otp: controller.otp.value,
                        payload: {
                          "work_detail": controller.workDetail.value,
                          "amount_charged":
                              double.tryParse(controller.amountCharged.value) ?? 0,
                          "parts_replaced": controller.partsReplaced.toList(),
                        },
                      );
                    },
              icon: controller.otpLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.verified_user),
              label: Text(
                controller.otpLoading.value
                    ? "Verifying..."
                    : "Verify & Complete Service",
              ),
            );
          })
        ),
      ),
    );
  }
}