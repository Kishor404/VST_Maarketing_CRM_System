import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.loadDashboard,
          displacement: 20,
          color: theme.primaryColor,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // --- Welcome Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overview',
                        style: theme.textTheme.labelLarge,
                      ),
                      Text(
                        'Dashboard',
                        style: theme.textTheme.headlineLarge,
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.notifications_none, color: theme.primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Main Highlight Card (Attendance) ---
              _buildAttendanceHero(context),

              const SizedBox(height: 24),

              _QuickStatsSection(controller: controller),
              const SizedBox(height: 32),

              // --- Refined Hint Section ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: theme.primaryColor),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Pull down to refresh your dashboard stats.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAttendanceHero(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        /// ============================
        /// Modern Gradient Background
        /// ============================
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor,
            theme.primaryColor.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        
      ),
      child: Stack(
        children: [
          /// ============================
          /// Decorative Background Elements
          /// ============================
          
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          /// ============================
          /// Main Content
          /// ============================
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header Row with Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Status',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateTime.now().toString().split(' ')[0],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              /// Status Value with Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.attendanceStatus.value.toUpperCase(),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: controller.attendanceStatus.value=="present"?const Color.fromARGB(255, 28, 211, 34):const Color.fromARGB(255, 255, 48, 33),
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          controller.attendanceStatus.value=="present"?'Keep up the excellent work!':"Ask the admin to mark you up !",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.75),
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  /// Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.25),
                      border: Border.all(
                        color: statusColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          controller.attendanceStatus.value=="present"?'Active':'Inactive',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ============================
  /// Helper Methods
  /// ============================

  Color _getStatusColor() {
    final status = controller.attendanceStatus.value.toLowerCase();
    if (status.contains('present')) {
      return const Color(0xFF10B981); // Green
    } else if (status.contains('absent')) {
      return const Color(0xFFEF4444); // Red
    } else if (status.contains('')) {
      return const Color(0xFFF59E0B); // Amber
    }
    return const Color(0xFF3B82F6); // Blue (default)
  }
}

/// ============================
/// Quick Stats Section
/// ============================

class _QuickStatsSection extends StatelessWidget {
  final HomeController controller;

  const _QuickStatsSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _MetricRow(
                  label: 'Total Completed',
                  value: '${controller.totalCompleted.value}',
                  icon: Icons.done_all_rounded,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(height: 16),
                Divider(
                  color: Colors.grey[400],
                  height: 0,
                ),
                const SizedBox(height: 16),
                _MetricRow(
                  label: 'Pending OTP',
                  value: '${controller.awaitingOtp.value}',
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 16),
                Divider(
                  color: Colors.grey[400],
                  height: 0,
                ),
                const SizedBox(height: 16),
                _MetricRow(
                  label: 'Rating Score',
                  value: '${controller.averageRating.value.toStringAsFixed(1)}/5',
                  icon: Icons.star_rate_rounded,
                  color: const Color(0xFF6366F1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ============================
/// Metric Row
/// ============================

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
        ),
      ],
    );
  }
}
