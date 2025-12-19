import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'profile_controller.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.loading.value) {
          return Center(child: CircularProgressIndicator(color: theme.primaryColor));
        }

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 0),
                children: [
                  /// ============================
                  /// 1. Unified Header (Avatar, Name, Role)
                  /// ============================
                  _buildUnifiedHeader(context, controller),
                  const SizedBox(height: 24),

                  /// ============================
                  /// 3. Profile Info Group (Minimalist List)
                  /// ============================
                  _buildInfoGroup(context, controller),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      }),
      
      /// ============================
      /// 4. Sticky Bottom Action (Logout)
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
          child: ElevatedButton.icon(
            onPressed: controller.logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
  
  // Custom builder for the Unified Header
  Widget _buildUnifiedHeader(BuildContext context, ProfileController controller) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.primaryColor.withOpacity(0.3), width: 2),
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: theme.colorScheme.secondary,
                child: Icon(Icons.person, size: 50, color: theme.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              controller.name.value,
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${controller.role.value.toUpperCase()} | ID: ${controller.id}', // Example ID
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom builder for the Profile Info List
  Widget _buildInfoGroup(BuildContext context, ProfileController controller) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.secondary, width: 1),
            ),
            child: Column(
              children: [
                _InfoListItem(
                  icon: Icons.badge_outlined,
                  label: 'Full Name',
                  value: controller.name.value,
                ),
                _InfoListItem(
                  icon: Icons.phone_outlined,
                  label: 'Primary Phone',
                  value: controller.phone.value,
                ),
                _InfoListItem(
                  icon: Icons.home_outlined,
                  label: 'Address',
                  value: controller.address.value,
                ),
                _InfoListItem(
                  icon: Icons.location_on_outlined,
                  label: 'Operating Region',
                  value: controller.region.value,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================
/// Info List Item (Modern Key-Value List)
/// ============================

class _InfoListItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoListItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: theme.primaryColor.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Text(
                value,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 52, // Align divider after icon
            color: theme.colorScheme.secondary,
          ),
      ],
    );
  }
}