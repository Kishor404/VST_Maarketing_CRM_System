import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/next_service_model.dart';
import '../../routes/app_routes.dart';
import 'home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      /// --------------------
      /// APP BAR (WHITE BG)
      /// --------------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset(
            'assets/images/vst_logo_transparent.png',
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
            onPressed: () => Get.toNamed(AppRoutes.PROFILE),
          ),
        ],
      ),

      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
                onRefresh: controller.refreshDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// --------------------
                            /// BANNER (RESPONSIVE)
                            /// --------------------
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: const DecorationImage(
                                    image: AssetImage(
                                        'assets/images/banner.png'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            /// --------------------
                            /// WELCOME
                            /// --------------------
                            Text(
                              'Welcome, ${controller.userName.value}',
                              style: theme.textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Manage your water purifier services with ease',
                              style: theme.textTheme.bodyMedium,
                            ),

                            const SizedBox(height: 24),

                            /// --------------------
                            /// STATS (RESPONSIVE)
                            /// --------------------
                            Row(
                              children: [
                                _BrandStatCard(
                                  title: 'Service Cards',
                                  value: controller.cardCount.value.toString(),
                                  icon: Icons.credit_card,
                                  onTap: () =>
                                      Get.toNamed(AppRoutes.CARDS),
                                ),
                                const SizedBox(width: 12),
                                _BrandStatCard(
                                  title: 'Active Services',
                                  value: controller.activeServiceCount.value
                                      .toString(),
                                  icon: Icons.build_circle,
                                  onTap: () =>
                                      Get.toNamed(AppRoutes.SERVICES),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            /// --------------------
                            /// PRIMARY CTA
                            /// --------------------
                            SizedBox(
                              height: 52,
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Book a Service'),
                                onPressed:
                                    controller.openServiceBookingFromHome,
                              ),
                            ),
                            
                            SizedBox(height: 32),

                            if (controller.nextServices.isNotEmpty) ...[
                              Text(
                                'Next Free Services',
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),

                              ...controller.nextServices.map(
                                (service) => _NextServiceTile(service: service),
                              ),
                            ],

                            const SizedBox(height: 20),

                            /// --------------------
                            /// QUICK ACTIONS
                            /// --------------------
                            Text(
                              'Quick Actions',
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 15),

                            _ActionTile(
                              icon: Icons.receipt_long_outlined,
                              title: 'Service History',
                              subtitle:
                                  'Completed & upcoming services',
                              onTap: () =>
                                  Get.toNamed(AppRoutes.SERVICES),
                            ),

                            SizedBox(height: 10),

                            _ActionTile(
                              icon: Icons.credit_card_outlined,
                              title: 'My Service Cards',
                              subtitle:
                                  'Warranty & service details',
                              onTap: () =>
                                  Get.toNamed(AppRoutes.CARDS),
                            ),

                            
                            SizedBox(height: 32),

                            /// --------------------
                            /// PUSH FOOTER DOWN
                            /// --------------------
                            const Spacer(),

                            /// --------------------
                            /// FOOTER (BOTTOM)
                            /// --------------------
                            Center(
                              child: Text(
                                'Crafted By CSBS Department of RIT',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
      bottomSheet: Container(
        height: 40,
        color: theme.colorScheme.primary,
        child: Center(
          child: Text(
            'Crafted By CSBS Department of RIT',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      )
    );
  }
}

class _NextServiceTile extends StatelessWidget {
  final NextServiceModel service;

  const _NextServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.primary.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: cs.primary),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.cardModel,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Next free service on ${service.nextServiceDate.toLocal().toString().split(' ')[0]}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          Text(
            'FREE',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


/// --------------------
/// STAT CARD
/// --------------------

class _BrandStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _BrandStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: cs.secondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: cs.primary.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              // Icon container (soft & rounded)
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: cs.primary,
                ),
              ),

              const SizedBox(width: 14),

              // Text section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withOpacity(0.65),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// --------------------
/// ACTION TILE
/// --------------------
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: cs.secondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: cs.primary.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            // Icon container (modern)
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                icon,
                size: 22,
                color: cs.primary,
              ),
            ),

            const SizedBox(width: 14),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Chevron
            Icon(
              Icons.chevron_right,
              color: theme.iconTheme.color?.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}
