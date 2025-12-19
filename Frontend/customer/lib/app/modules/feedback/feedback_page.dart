import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vst_maarketing/app/core/utils/app_snackbar.dart';

import 'feedback_controller.dart';

class FeedbackPage extends GetView<FeedbackController> {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final int serviceId = Get.arguments as int;

    final TextEditingController commentController =
        TextEditingController();

    final RxInt rating = 0.obs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Feedback'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          return ListView(
            children: [

              /// Rating
              const Text(
                'Rate the service',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      rating.value > index
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      rating.value = index + 1;
                    },
                  );
                }),
              ),

              const SizedBox(height: 20),

              /// Comments
              TextField(
                controller: commentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Comments (optional)',
                  hintText: 'Share your experience',
                ),
              ),

              const SizedBox(height: 30),

              /// Submit button
              ElevatedButton(
                onPressed: controller.loading.value
                    ? null
                    : () async {
                        if (rating.value == 0) {
                          AppSnackbar.error(
                            'Error',
                            'Please select a rating',
                          );
                          return;
                        }

                        await controller.submitFeedback(
                          serviceId: serviceId,
                          rating: rating.value,
                          comments:
                              commentController.text.trim(),
                        );
                      },
                child: controller.loading.value
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text('Submit Feedback'),
              ),
            ],
          );
        }),
      ),
    );
  }
}
