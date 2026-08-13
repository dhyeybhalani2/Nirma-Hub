import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ai/widgets/skeleton_loaders.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'notes_screen.dart'; // For PdfViewerScreen
import 'package:url_launcher/url_launcher.dart';

class UniversityUpdatesScreen extends ConsumerStatefulWidget {
  const UniversityUpdatesScreen({super.key});

  @override
  ConsumerState<UniversityUpdatesScreen> createState() => _UniversityUpdatesScreenState();
}

class _UniversityUpdatesScreenState extends ConsumerState<UniversityUpdatesScreen> {
  final Color nirmaNavy = const Color(0xFF1A2B48);
  final Color nirmaRed = const Color(0xFFC62828);
  final Color textDark = const Color(0xFF0F172A);
  final Color textGray = const Color(0xFF64748B);
  final Color borderGray = const Color(0xFFCBD5E1);
  final Color scaffoldBg = const Color(0xFFF1F4F9);

  bool _isLoading = true;
  List<Map<String, dynamic>> _updates = [];

  @override
  void initState() {
    super.initState();
    _fetchUpdates();
  }

  Future<void> _fetchUpdates() async {
    try {
      final authState = ref.read(authNotifierProvider);
      final userProfile = authState.value;
      
      final userYear = userProfile?.academicYear ?? 'All';
      final userBranch = userProfile?.branch ?? 'All';

      var query = Supabase.instance.client
          .from('university_updates')
          .select()
          .eq('is_active', true);

      // Only filter by year if the student has set a specific year
      if (userYear != 'All') {
        query = query.inFilter('target_year', ['All', userYear]);
      }

      // Only filter by branch if the student has set a specific branch
      if (userBranch != 'All') {
        query = query.inFilter('target_branch', ['All', userBranch]);
      }

      final data = await query.order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _updates = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load updates: $e')),
        );
      }
    }
  }

  void _openFile(String url, String title, {DateTime? timestamp}) {
    if (url.toLowerCase().contains('.pdf') || title.toLowerCase().endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            pdfTitle: title,
            pdfUrl: url,
            pdfType: 'University Update',
            pdfTimestamp: timestamp,
          ),
        ),
      );
    } else {
      // For images or other links, use the exact same in-app browser view
      try {
        final uri = Uri.parse(url);
        launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open the file link.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 8,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(CupertinoIcons.arrow_left, color: Theme.of(context).colorScheme.onSurface, size: 18),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'University Updates',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
            fontFamily: 'Manrope',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        ),
      ),
      body: _isLoading
          ? const UniversityUpdatesSkeleton()
          : RefreshIndicator(
              color: nirmaRed,
              onRefresh: _fetchUpdates,
              child: _updates.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.news, size: 64, color: borderGray),
                            SizedBox(height: 16),
                            Text(
                              'No updates right now.',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textGray,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      itemCount: _updates.length,
                      itemBuilder: (context, index) {
                        final update = _updates[index];
                        final title = update['title'] ?? 'Update';
                        final description = update['description'] ?? '';
                        final fileUrl = update['file_url'];
                        final createdAtStr = update['created_at'];
                        DateTime? date;
                        bool isNew = false;
                        if (createdAtStr != null) {
                          date = DateTime.tryParse(createdAtStr);
                          if (date != null) {
                            final difference = DateTime.now().difference(date);
                            // Tag as NEW if the post is less than 7 days old
                            isNew = difference.inDays <= 7;
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderGray, width: 1.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (isNew)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: nirmaRed.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'NEW',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: nirmaRed,
                                                letterSpacing: 1.2,
                                                fontFamily: 'Manrope',
                                              ),
                                            ),
                                          ),
                                        if (isNew) Spacer(),
                                        if (date != null)
                                          Text(
                                            DateFormat('MMM d, yyyy').format(date),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: textGray,
                                              fontFamily: 'Manrope',
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: textDark,
                                        fontFamily: 'Manrope',
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: textGray,
                                        height: 1.5,
                                        fontFamily: 'Manrope',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (fileUrl != null && fileUrl.toString().trim().isNotEmpty) ...[
                                Container(height: 1, color: borderGray.withValues(alpha: 0.5)),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                                    splashColor: const Color(0xFFE5202B).withValues(alpha: 0.1),
                                    highlightColor: const Color(0xFFE5202B).withValues(alpha: 0.05),
                                    onTap: () {
                                      Future.delayed(const Duration(milliseconds: 120), () {
                                        _openFile(fileUrl, title);
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            fileUrl.toLowerCase().endsWith('.pdf') 
                                                ? CupertinoIcons.doc_text_fill 
                                                : CupertinoIcons.photo_fill,
                                            color: nirmaNavy,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'View Attachment',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1A2B48),
                                              fontFamily: 'Manrope',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
