import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'work_controller.dart';

class WorkCompletionPage extends GetView<WorkController> {
  const WorkCompletionPage({super.key});

  Future<void> pickJobCardImage(int index) async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.camera, // or gallery
      imageQuality: 70,
    );

    if (picked != null) {
      controller.jobCards[index]["image"] = File(picked.path);
      controller.jobCards.refresh();
    }
  }


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
            /// Job Card Section (UPDATED)
            /// ============================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Job Cards',
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
                ),
                TextButton.icon(
                  onPressed: () {
                    controller.jobCards.add({
                      "part_name": "",
                      "details": "",
                      "image": null,
                    });
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text("Add Card"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "(If parts are taken to the workshop)",
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),

            Obx(() {
              if (controller.jobCards.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.assignment_outlined, color: Colors.grey, size: 40),
                      SizedBox(height: 8),
                      Text("No Workshop Job Cards Created",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Column(
                children: List.generate(controller.jobCards.length, (index) {
                  final jc = controller.jobCards[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        // --- Card Header ---
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.05),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: theme.colorScheme.primary,
                                child: Text("${index + 1}", 
                                  style: const TextStyle(fontSize: 12, color: Colors.white)),
                              ),
                              const SizedBox(width: 10),
                              const Text("Workshop Item", 
                                style: TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                                onPressed: () => controller.jobCards.removeAt(index),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: "Part Name",
                                  prefixIcon: Icon(Icons.settings_suggest_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) => controller.jobCards[index]["part_name"] = v,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: "Problem Details",
                                  alignLabelWithHint: true,
                                  prefixIcon: Icon(Icons.edit_note),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) => controller.jobCards[index]["details"] = v,
                              ),
                              const SizedBox(height: 16),
                              
                              // --- Image Preview Area ---
                              Obx(() {
                                final image = controller.jobCards[index]["image"];
                                return GestureDetector(
                                  onTap: () => pickJobCardImage(index),
                                  child: Container(
                                    width: double.infinity,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                    ),
                                    child: image != null
                                        ? Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.file(image, fit: BoxFit.cover),
                                              ),
                                              Positioned(
                                                right: 8,
                                                top: 8,
                                                child: CircleAvatar(
                                                  backgroundColor: Colors.black54,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                                    onPressed: () => pickJobCardImage(index),
                                                  ),
                                                ),
                                              )
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                                              SizedBox(height: 4),
                                              Text("Tap to capture item image", 
                                                style: TextStyle(color: Colors.grey, fontSize: 12)),
                                            ],
                                          ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            }),


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

                          /// 🔥 JOB CARDS
                          "job_cards": controller.jobCards.map((jc) {
                            return {
                              "part_name": jc["part_name"],
                              "details": jc["details"],
                            };
                          }).toList(),
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