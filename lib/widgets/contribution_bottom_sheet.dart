import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContributionBottomSheet extends StatelessWidget {
  final String subjectName;
  final String specialThanks;
  final bool isPyq;

  const ContributionBottomSheet({
    super.key,
    required this.subjectName,
    required this.specialThanks,
    required this.isPyq,
  });

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _launchEmail(BuildContext context) async {
    final String subjectLine = isPyq 
        ? 'Contributing PYQ Solutions for $subjectName'
        : 'Contributing Notes for $subjectName';
    
    final String bodyText = isPyq
        ? 'Hi, I would like to contribute solutions for the previous year questions of this subject.'
        : 'Hi, I would like to contribute some notes/materials for this subject.';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'backlogon@gmail.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': subjectLine,
        'body': bodyText,
      }),
    );
    
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open email app")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawThanks = (specialThanks.trim().isEmpty) ? 'Be the first to contribute!' : specialThanks;
    
    // Split by comma, trim whitespace, and join with newlines for vertical display
    final displayThanks = rawThanks.split(',').map((s) => s.trim()).join('\n');

    return Container(
      padding: const EdgeInsets.only(
        top: 10,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer, // App background (bgSurface)
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5202B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.volunteer_activism_rounded,
                  color: Color(0xFFE5202B),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Help Other Students",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    Text(
                      isPyq ? "Got solutions for these PYQs? Share them!" : "Have better notes? Share them with juniors!",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 16,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          
          // Mail Button
          InkWell(
            onTap: () => _launchEmail(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_rounded, color: Theme.of(context).colorScheme.surface, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Mail us your materials",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 32),
          
          // Special Thanks Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_rounded, color: Theme.of(context).colorScheme.error, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Special Thanks To",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                        fontFamily: 'Manrope',
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.favorite_rounded, color: Theme.of(context).colorScheme.error, size: 18),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(
                    maxHeight: 120, // Give it a max height so it scrolls if too long
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      displayThanks,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
