import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.secondary,
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.user.value;
        if (user == null) {
          return const Center(child: Text('No profile data found'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              /// --------------------
              /// Profile Header Card
              /// --------------------
              
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  
                  
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor:Colors.white,
                      child: Icon(
                        Icons.person_outline,
                        size: 44,
                        color: cs.primary,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      user.name+" ("+user.id.toString()+")",
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      user.phone,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// --------------------
              /// Info Section
              /// --------------------
              _SectionCard(
                title: 'Account Info',
                children: [
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    title: 'Role',
                    value: user.role.toUpperCase(),
                  ),
                  if (user.region != null)
                    _InfoTile(
                      icon: Icons.map_outlined,
                      title: 'Region',
                      value: user.region!,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              /// --------------------
              /// Address Section
              /// --------------------
              if (user.address != null ||
                  user.city != null ||
                  user.postalCode != null)
                _SectionCard(
                  title: 'Address',
                  children: [
                    if (user.address != null)
                      _InfoTile(
                        icon: Icons.home_outlined,
                        title: 'Street Address',
                        value: user.address!,
                      ),
                    if (user.city != null)
                      _InfoTile(
                        icon: Icons.location_city_outlined,
                        title: 'City',
                        value: user.city!,
                      ),
                    if (user.postalCode != null)
                      _InfoTile(
                        icon: Icons.local_post_office_outlined,
                        title: 'Postal Code',
                        value: user.postalCode!,
                      ),
                  ],
                ),

              const SizedBox(height: 28),

              /// --------------------
              /// Logout
              /// --------------------
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: controller.logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
}

/// --------------------
/// Section Card
/// --------------------
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// --------------------
/// Reusable Info Tile
/// --------------------
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
