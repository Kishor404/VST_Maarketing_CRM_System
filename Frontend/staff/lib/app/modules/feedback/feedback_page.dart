import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'feedback_controller.dart';

class FeedbackPage extends GetView<FeedbackController> {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Ensure the Scaffold background is consistent with the theme
      backgroundColor: theme.scaffoldBackgroundColor, 
      body: Obx(() {
        if (controller.loading.value) {
          return Center(child: CircularProgressIndicator(color: theme.primaryColor));
        }

        if (controller.feedbacks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 60,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Feedback Received',
                  style: theme.textTheme.headlineMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your services await customer reviews.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchFeedbacks,
          color: theme.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: controller.feedbacks.length,
            itemBuilder: (_, index) {
              final feedback = controller.feedbacks[index];
              return _ElegantFeedbackCard(feedback: feedback);
            },
          ),
        );
      }),
    );
  }
}

/// ============================
/// Elegant Feedback Card
/// ============================

class _ElegantFeedbackCard extends StatelessWidget {
  final dynamic feedback; // Using dynamic since the model is not defined here

  const _ElegantFeedbackCard({
    required this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final double ratingScore = feedback.rating.toDouble();
    
    // Determine color based on rating for visual feedback
    Color scoreColor;
    if (ratingScore >= 4.0) {
      scoreColor = Colors.green.shade600;
    } else if (ratingScore >= 3.0) {
      scoreColor = Colors.orange.shade600;
    } else {
      scoreColor = Colors.red.shade600;
    }

    // Get initials for the avatar placeholder
    String customerName = feedback.customerLabel ?? 'Anonymous';
    String initials = customerName.split(' ').map((name) => name.isNotEmpty ? name[0] : '').join().toUpperCase();
    if (initials.isEmpty) initials = '?';


    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Soft border and subtle shadow for an elegant look
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          /// 1. Header: Avatar, Name, and Large Rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Avatar and Name Group
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.secondary,
                    radius: 20,
                    child: Text(
                      initials.length > 2 ? initials.substring(0, 2) : initials,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    customerName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
              
              // Large Rating Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ratingScore.toStringAsFixed(1),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                    color: scoreColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE6EEF6)), 
          const SizedBox(height: 12),

          /// 2. Star Rating and Comment
          
          // Star Indicator
          RatingBarIndicator(
            rating: ratingScore,
            itemBuilder: (_, __) => Icon(
              Icons.star_rounded,
              color: scoreColor,
            ),
            itemCount: 5,
            itemSize: 20,
            unratedColor: Colors.grey.shade300,
          ),
          
          const SizedBox(height: 8),

          // Comment
          if (feedback.comments != null && feedback.comments!.isNotEmpty)
            Text(
              feedback.comments!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF2E3A44),
                height: 1.4,
              ),
            )
          else
            Text(
              "The customer left a rating but no written comments.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          
          const SizedBox(height: 16),

          /// 3. Footer (Date)
          Text(
            'Reviewed on: ${feedback.createdAtFormatted ?? '-'}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}