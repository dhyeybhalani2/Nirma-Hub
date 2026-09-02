import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class LinkAccountPromoSheet extends StatelessWidget {
  final String platform;
  final Color primaryColor;
  final VoidCallback onLinkPressed;

  const LinkAccountPromoSheet({
    super.key,
    required this.platform,
    required this.primaryColor,
    required this.onLinkPressed,
  });

  static Future<void> show(BuildContext context, {
    required String platform,
    required Color primaryColor,
    required VoidCallback onLinkPressed,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LinkAccountPromoSheet(
        platform: platform,
        primaryColor: primaryColor,
        onLinkPressed: onLinkPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Stack(
              alignment: Alignment.topCenter,
              children: [
                // Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 8),
                // Custom Chain Icon area with glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      CupertinoIcons.link,
                      size: 32,
                      color: primaryColor,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(text: 'Link Your '),
                        TextSpan(
                          text: platform,
                          style: TextStyle(color: primaryColor),
                        ),
                        TextSpan(text: ' Account'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Features Container
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        context: context,
                        icon: Icons.trending_up,
                        iconColor: const Color(0xFFEF4444), // Red
                        title: 'Track Your Progress',
                        subtitle: 'View your rating, rank and contest history in real-time.',
                      ),
                      SizedBox(height: 12),
                      _buildFeatureItem(
                        context: context,
                        icon: CupertinoIcons.person_3,
                        iconColor: const Color(0xFF3B82F6), // Blue
                        title: 'Compete with Peers',
                        subtitle: 'See how you rank among your friends and classmates.',
                      ),
                      SizedBox(height: 12),
                      _buildFeatureItem(
                        context: context,
                        icon: CupertinoIcons.rosette,
                        iconColor: const Color(0xFFEF4444), // Red
                        title: 'Stay Motivated',
                        subtitle: 'Keep improving and climb the leaderboard together.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                // Link Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onLinkPressed();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(CupertinoIcons.link),
                      label: Text(
                        'Link $platform Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
            // Close Button
            Positioned(
              top: 0,
              right: 16,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: Icon(Icons.close, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'Manrope',
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
