import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'service_booking_controller.dart';
import 'package:flutter/services.dart';

class ServiceBookingPage extends GetView<ServiceBookingController> {
  const ServiceBookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Service'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// -----------------
              /// Illustration Header
              /// -----------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: cs.secondary,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: cs.primary.withOpacity(0.06),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 72,
                      width: 72,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.build_circle_outlined,
                        size: 40,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Schedule a Service',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We’ll take care of your service needs',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// -----------------
              /// Form Card
              /// -----------------
              Container(
                padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cs.secondary,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: cs.primary.withOpacity(0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Section title
                      Text(
                        'Service Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Tell us about the issue and preferred date',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              theme.textTheme.bodyMedium?.color?.withOpacity(0.65),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Service Card Dropdown
                      DropdownButtonFormField(
                        decoration: InputDecoration(
                          hintText: 'Select your service card',
                          filled: true,
                          fillColor: theme.scaffoldBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        value: controller.selectedCard.value,
                        items: controller.cards.map((card) {
                          return DropdownMenuItem(
                            value: card,
                            child: Text(
                              '${card.model} • ${card.address}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          controller.selectedCard.value = value;
                        },
                      ),

                      const SizedBox(height: 14),

                     /// Complaint Type Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: 'Select complaint',
                          filled: true,
                          fillColor: theme.scaffoldBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        value: controller.complaintType.value,
                        items: controller.complaintOptions.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          );
                        }).toList(),
                        onChanged: (value) {
                          controller.complaintType.value = value;
                          if (value != 'Other') {
                            controller.complaint.value = value ?? '';
                          }
                        },
                      ),

                      /// Show only when "Other" selected
                      Obx(() {
                        if (controller.complaintType.value != 'Other') {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: TextField(
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Describe complaint',
                              hintText: 'Enter your complaint',
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (v) {
                              controller.customComplaint.value = v;
                              controller.complaint.value = v;
                            },
                          ),
                        );
                      }),


                      const SizedBox(height: 14),

                      /// Preferred Date
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                            initialDate: DateTime.now(),
                          );
                          if (picked != null) {
                            controller.preferredDate.value = picked;
                          }
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 20,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 12),
                              Obx(
                                () => Text(
                                  controller.preferredDate.value == null
                                      ? 'Preferred date'
                                      : controller.preferredDate.value!
                                          .toLocal()
                                          .toString()
                                          .split(' ')[0],
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.expand_more,
                                color: theme.iconTheme.color?.withOpacity(0.6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                ,

              const SizedBox(height: 24),

              /// -----------------
              /// Submit Button
              /// -----------------
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    _showBookingConfirmation(context);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Book Service',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showBookingConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          final AnimationController anim = AnimationController(
            vsync: Navigator.of(context),
            duration: const Duration(milliseconds: 900),
          )..repeat(reverse: true);

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text(
                  'Confirm Booking',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Slide the button below to confirm your booking.',
                  style: theme.textTheme.bodyMedium,
                ),

                const SizedBox(height: 20),

                _summaryRow('Card', controller.selectedCard.value?.model ?? '-'),
                _summaryRow(
                  'Complaint',
                  controller.complaint.value.isEmpty
                      ? '-'
                      : controller.complaint.value,
                ),
                _summaryRow(
                  'Date',
                  controller.preferredDate.value == null
                      ? '-'
                      : controller.preferredDate.value!
                          .toLocal()
                          .toString()
                          .split(' ')[0],
                ),

                const SizedBox(height: 24),

                /// 🔔 Hint animation (arrow nudge)
                AnimatedBuilder(
                  animation: anim,
                  builder: (_, __) {
                    return Transform.translate(
                      offset: Offset(8 * anim.value, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: cs.primary.withOpacity(0.9),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Slide to confirm',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.primary.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                /// SLIDE TO BOOK
                SlideAction(
                  height: 56,
                  elevation: 0,
                  borderRadius: 20,
                  outerColor: cs.primary.withAlpha(20),
                  innerColor: cs.primary,
                  text: 'Slide to confirm booking >>>',
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    color: cs.primary.withOpacity(0.75),
                    fontWeight: FontWeight.w600,
                  ),
                  sliderButtonIcon: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  sliderRotate: false,
                  onSubmit: () async {
                    anim.stop();
                    HapticFeedback.selectionClick();
                    HapticFeedback.mediumImpact();
                    await Future.delayed(const Duration(milliseconds: 300));
                    await controller.submitBooking();
                  },
                ),

                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );

  }
  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }


}

