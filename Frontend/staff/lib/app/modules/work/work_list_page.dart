import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'work_controller.dart';
import 'work_detail_page.dart';

class WorkPage extends GetView<WorkController> {
  const WorkPage({super.key});

  List _sortServices(List services, {required bool completed}) {
    final List sorted = List.from(services);

    sorted.sort((a, b) {
      DateTime? da = _parseDate(a.scheduledAt);
      DateTime? db = _parseDate(b.scheduledAt);

      // nulls always last
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;

      // assigned → earliest first
      if (!completed) {
        return da.compareTo(db);
      }

      // completed → latest first
      return db.compareTo(da);
    });

    return sorted;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Obx(() {
        return FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          onPressed: controller.loading.value
              ? null
              : () {
                  controller.loadAll();
                },
          child: controller.loading.value
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh),
        );
      }),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            /// ============================
            /// Custom Modern Tab Bar
            /// ============================
            Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 0,
              child: TabBar(
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey[500],
                indicatorColor: Theme.of(context).primaryColor,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3,
                labelStyle:
                    Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                unselectedLabelStyle:
                    Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                tabs: const [
                  Tab(text: "Assigned"),
                  Tab(text: "Completed"),
                ],
              ),
            ),

            /// ============================
            /// Tab Views
            /// ============================
            Expanded(
              child: Container(
                color: Colors.white,
                child: Obx(() {
                  if (controller.loading.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading services...',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  return TabBarView(
                    children: [
                      _buildList(
                        context,
                        controller.assignedServices,
                        completed: false,
                      ),
                      _buildList(
                        context,
                        controller.completedServices,
                        completed: true,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildList(
    BuildContext context,
    List services, {
    required bool completed,
  }) {
    if (services.isEmpty) {
      return _EmptyStateWidget(
        icon: completed ? Icons.check_circle_outline : Icons.assignment_outlined,
        title: completed ? 'No Completed Services' : 'No Assigned Services',
        description: completed
            ? 'Services you complete will appear here'
            : 'New services will be assigned to you',
        completed: completed,
      );
    }

    final sortedServices =_sortServices(services, completed: completed);
    return ListView.separated(
      itemCount: sortedServices.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (_, index) {
        final service = sortedServices[index];

        return _WorkServiceCard(
          service: service,
          completed: completed,
          onTap: () {
            Get.to(
              () => const WorkDetailPage(),
              arguments: service.id,
            );
          },
        );
      },
    );
  }
}

/// ============================
/// Work Service Card Widget
/// ============================

class _WorkServiceCard extends StatefulWidget {
  final dynamic service;
  final bool completed;
  final VoidCallback onTap;

  const _WorkServiceCard({
    required this.service,
    required this.completed,
    required this.onTap,
  });

  @override
  State<_WorkServiceCard> createState() => _WorkServiceCardState();
}

class _WorkServiceCardState extends State<_WorkServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    _animationController.forward();
  }

  void _onTapUp(_) {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.completed
        ? const Color(0xFF10B981) // Green
        : const Color(0xFFF59E0B); // Amber

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color.fromARGB(255, 138, 138, 138), // Specify the color of the bottom border
                  width: 1.0,        // Specify the width of the bottom border
                ),
              ),
              color: const Color.fromARGB(255, 255, 255, 255)
            ),
            
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header with Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Icon Container
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.completed
                            ? Icons.check_circle_rounded
                            : Icons.assignment_rounded,
                        size: 24,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service ${widget.service.id ?? '??'} For ${widget.service.customerName ?? "Unknown"}',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).primaryColor,
                                    ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complaint: ${widget.service.description ?? 'N/A'}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    /// Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.completed ? 'Done' : 'Pending',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================
/// Empty State Widget
/// ============================

class _EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool completed;

  const _EmptyStateWidget({
    required this.icon,
    required this.title,
    required this.description,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = completed
        ? const Color(0xFF10B981) // Green
        : const Color(0xFFF59E0B); // Amber

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Icon Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 56,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 24),

            /// Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 8),

            /// Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 32),

            /// Decorative Elements
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}