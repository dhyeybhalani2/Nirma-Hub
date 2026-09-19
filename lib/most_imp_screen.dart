import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'search_helper.dart';
import 'notes_screen.dart';
import 'widgets/premium_touch_button.dart';
import 'widgets/skeleton_loaders.dart';
import 'services/analytics_service.dart';
import 'core/theme/app_theme.dart';

// ─────────────────────────────────────────────
// Design System Tokens
// ─────────────────────────────────────────────

class MostImpScreen extends ConsumerStatefulWidget {
  const MostImpScreen({super.key});

  @override
  ConsumerState<MostImpScreen> createState() => _MostImpScreenState();
}

class _MostImpScreenState extends ConsumerState<MostImpScreen> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _subjects = [];
  Set<String> _subjectsWithImp = {};
  bool _isLoading = true;
  String _currentYear = '';
  String _currentBranch = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfile = ref.read(authNotifierProvider).value;
      final academicYear = userProfile?.academicYear ?? '1st';
      final branch = userProfile?.branch ?? 'Common';
      _currentYear = academicYear;
      _currentBranch = branch;
      _fetchDynamicSubjects(academicYear, branch);
    });
  }

  Future<void> _fetchDynamicSubjects(String rawAcademicYear, String userBranch) async {
    if (mounted) setState(() => _isLoading = true);

    String academicYear = rawAcademicYear.isEmpty ? "1st" : rawAcademicYear;
    if (academicYear.toLowerCase().contains("1st")) academicYear = "1st";
    else if (academicYear.toLowerCase().contains("2nd")) academicYear = "2nd";
    else if (academicYear.toLowerCase().contains("3rd")) academicYear = "3rd";
    else if (academicYear.toLowerCase().contains("4th")) academicYear = "4th";

    try {
      // 1. Fetch Subjects for this student's year and branch (same exact query as Notes & PYQs)
      var query = Supabase.instance.client
          .from('subjects')
          .select('*')
          .eq('academic_year', academicYear);

      if (academicYear != '1st' && userBranch.isNotEmpty) {
        query = query.or('branch.eq.$userBranch,branch.eq.Common');
      }

      final subjectsData = await query.order('name');

      // 2. Fetch IDs of subjects that have valid IMP Master Guides with actual questions
      Set<String> impSubjectIds = {};
      try {
        final impGuidesData = await Supabase.instance.client
            .from('imp_questions')
            .select('subject_id, modules');

        impSubjectIds = (impGuidesData as List<dynamic>)
            .where((i) {
              final modules = i['modules'];
              if (modules is List && modules.isNotEmpty) {
                return modules.any((m) {
                  final topics = m['topics'];
                  if (topics is List && topics.isNotEmpty) {
                    return topics.any((t) => t['questions'] is List && (t['questions'] as List).isNotEmpty);
                  }
                  return m['questions'] is List && (m['questions'] as List).isNotEmpty;
                });
              }
              return false;
            })
            .map((i) => i['subject_id']?.toString())
            .whereType<String>()
            .toSet();
      } catch (impErr) {
        debugPrint("imp_questions check: $impErr");
      }

      final mapped = (subjectsData as List<dynamic>).map((s) {
        final name = (s['name'] ?? '') as String;
        final subId = s['id']?.toString() ?? '';
        return {
          'id': subId,
          'name': name,
          'code': s['code'] ?? '',
          'branch': s['branch'] ?? '',
          'academic_year': s['academic_year'] ?? '',
          'has_imp': impSubjectIds.contains(subId),
          'color': _getColorForSubject(name),
          'iconColor': _getIconColorForSubject(name),
          'icon': _getIconForSubject(name),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _subjects = mapped;
          _subjectsWithImp = impSubjectIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching dynamic IMP subjects: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getIconForSubject(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math') || lower.contains('stat')) return Icons.calculate;
    if (lower.contains('comput') || lower.contains('ai') || lower.contains('web') || lower.contains('prog') || lower.contains('data')) return Icons.computer;
    if (lower.contains('electric') || lower.contains('ece') || lower.contains('circ') || lower.contains('sensor')) return Icons.electrical_services;
    if (lower.contains('mech') || lower.contains('machine')) return Icons.settings;
    if (lower.contains('civil') || lower.contains('arch')) return Icons.architecture;
    if (lower.contains('chem') || lower.contains('bio') || lower.contains('pharma') || lower.contains('env')) return Icons.science;
    if (lower.contains('phys') || lower.contains('laser')) return Icons.lightbulb_outline;
    if (lower.contains('english') || lower.contains('comm')) return Icons.chat_bubble_outline;
    return Icons.library_books;
  }

  Color _getColorForSubject(String name) {
    final hash = name.hashCode.abs();
    if (context.c.isDark) return _getIconColorForSubject(name).withValues(alpha: 0.16);
    final colors = [
      const Color(0xFFE8F5E9), const Color(0xFFE3F2FD), const Color(0xFFF3E5F5),
      context.c.warningSoft, context.c.warningSoft, const Color(0xFFE0F7FA),
      const Color(0xFFFCE4EC), const Color(0xFFE8EAF6), const Color(0xFFFBE9E7)
    ];
    return colors[hash % colors.length];
  }

  Color _getIconColorForSubject(String name) {
    final hash = name.hashCode.abs();
    final colors = [
      const Color(0xFF388E3C), const Color(0xFF1976D2), const Color(0xFF7B1FA2),
      const Color(0xFFF57C00), const Color(0xFFFBC02D), const Color(0xFF0097A7),
      const Color(0xFFC2185B), const Color(0xFF3F51B5), const Color(0xFFD84315)
    ];
    return context.c.tint(colors[hash % colors.length]);
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(authNotifierProvider).value;
    final academicYear = userProfile?.academicYear ?? '1st';
    final branch = userProfile?.branch ?? 'Common';

    if ((academicYear != _currentYear || branch != _currentBranch) && academicYear.isNotEmpty) {
      _currentYear = academicYear;
      _currentBranch = branch;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchDynamicSubjects(academicYear, branch);
      });
    }

    final theme = Theme.of(context);

    // Filter subjects based on search query
    final filteredSubjects = _subjects.where((subject) {
      final name = (subject['name'] as String).toLowerCase();
      final code = (subject['code'] as String).toLowerCase();
      final shortForm = generateShortForm(name);
      final q = _searchQuery.toLowerCase().trim();
      return name.contains(q) || code.contains(q) || shortForm.contains(q.replaceAll(RegExp(r'[^a-z0-9]'), ''));
    }).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainer,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
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
                  child: Icon(CupertinoIcons.arrow_left, color: theme.colorScheme.onSurface, size: 18),
                ),
              ),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.colorScheme.outlineVariant, height: 1),
        ),
        title: Text(
          "Most IMP",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            fontFamily: 'Manrope',
          ),
        ),
      ),
      body: _isLoading
          ? const ListSkeleton()
          : _subjects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.folder_open, size: 64, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          "There is no IMP Uploaded for current year",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface, fontFamily: 'Manrope'),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: context.c.accent,
                  onRefresh: () => _fetchDynamicSubjects(academicYear, branch),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                          child: _buildSearchBar(theme),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final subject = filteredSubjects[index];
                              final bool hasImp = subject['has_imp'] == true;

                              final subjectCard = Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: PremiumTouchButton(
                                  enableRipple: false,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: context.c.shadow.withValues(alpha: 0.02),
                                          blurRadius: 10,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: theme.colorScheme.surface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        side: BorderSide(
                                          color: hasImp 
                                              ? const Color(0xFF10B981).withValues(alpha: 0.35) 
                                              : theme.colorScheme.outlineVariant, 
                                          width: hasImp ? 1.2 : 1.0,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        splashColor: context.c.accent.withValues(alpha: 0.10),
                                        highlightColor: context.c.accent.withValues(alpha: 0.05),
                                        onTap: () {
                                          Future.delayed(const Duration(milliseconds: 120), () {
                                            Navigator.push(
                                              context,
                                              CupertinoPageRoute(
                                                builder: (context) => ImpSubjectDetailScreen(
                                                  subjectId: subject["id"],
                                                  subjectName: subject["name"], 
                                                  subjectCode: subject["code"],
                                                ),
                                              ),
                                            );
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          child: Row(
                                            children: [
                                              // Subject Icon
                                              Container(
                                                width: 40,
                                                height: 40,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: (subject["iconColor"] as Color).withValues(alpha: 0.05),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: (subject["iconColor"] as Color).withValues(alpha: 0.1),
                                                  ),
                                                ),
                                                child: Icon(subject["icon"], color: subject["iconColor"], size: 20),
                                              ),

                                              const SizedBox(width: 16),

                                              // Subject Name & Code / Live Tag
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      subject["name"],
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w800,
                                                        color: theme.colorScheme.onSurface,
                                                        fontFamily: 'Manrope',
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        if ((subject["code"] as String).isNotEmpty) ...[
                                                          Text(
                                                            subject["code"],
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w600,
                                                              color: theme.colorScheme.onSurfaceVariant,
                                                              fontFamily: 'Manrope',
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                        ],
                                                        if (hasImp)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: const Text(
                                                              "⚡ LIVE IMP",
                                                              style: TextStyle(
                                                                fontSize: 10.5,
                                                                fontWeight: FontWeight.w800,
                                                                color: Color(0xFF10B981),
                                                                fontFamily: 'Manrope',
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Trailing Chevron
                                              Icon(CupertinoIcons.chevron_forward, color: context.c.borderStrong, size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );

                              return subjectCard;
                            },
                            childCount: filteredSubjects.length,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return TextField(
      onChanged: (val) => setState(() => _searchQuery = val),
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface, fontFamily: 'Manrope'),
      cursorColor: context.c.accent,
      decoration: InputDecoration(
        hintText: 'Search subjects or codes...',
        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 15),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 22.0, right: 8.0),
          child: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Dynamic Subject Master Guide Detail Viewer
// ─────────────────────────────────────────────
class ImpSubjectDetailScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String subjectCode;

  const ImpSubjectDetailScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
  });

  @override
  State<ImpSubjectDetailScreen> createState() => _ImpSubjectDetailScreenState();
}

class _ImpSubjectDetailScreenState extends State<ImpSubjectDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _guideData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    AnalyticsService.startImpSession(
      widget.subjectName,
      subjectId: widget.subjectId,
      subjectCode: widget.subjectCode,
    );
    _loadGuide();
  }

  @override
  void dispose() {
    AnalyticsService.endImpSession();
    super.dispose();
  }

  Future<void> _loadGuide() async {
    final cacheKey = 'imp_guide_cache_${widget.subjectId}';
    final prefs = await SharedPreferences.getInstance();

    // 1. Try local cache first for instant rendering
    final cachedJson = prefs.getString(cacheKey);
    if (cachedJson != null) {
      try {
        setState(() {
          _guideData = jsonDecode(cachedJson);
          _isLoading = false;
        });
      } catch (_) {}
    }

    // 2. Fetch fresh data from Supabase
    try {
      final response = await Supabase.instance.client
          .from('imp_questions')
          .select('*')
          .eq('subject_id', widget.subjectId)
          .maybeSingle();

      if (response != null) {
        final modules = response['modules'];
        bool hasActualQuestions = false;
        if (modules is List && modules.isNotEmpty) {
          hasActualQuestions = modules.any((m) {
            final topics = m['topics'];
            if (topics is List && topics.isNotEmpty) {
              return topics.any((t) => t['questions'] is List && (t['questions'] as List).isNotEmpty);
            }
            return m['questions'] is List && (m['questions'] as List).isNotEmpty;
          });
        }

        if (hasActualQuestions) {
          await prefs.setString(cacheKey, jsonEncode(response));
          if (mounted) {
            setState(() {
              _guideData = response;
              _isLoading = false;
            });
          }
        } else {
          // If modules are empty or cleared, clear the cache and show empty state
          await prefs.remove(cacheKey);
          if (mounted) {
            setState(() {
              _guideData = null;
              _isLoading = false;
            });
          }
        }
      } else {
        // If deleted in Supabase, invalidate cache and show empty state
        await prefs.remove(cacheKey);
        if (mounted) {
          setState(() {
            _guideData = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading guide: $e");
      if (mounted) {
        setState(() {
          if (_guideData == null) {
            _errorMessage = e.toString();
          }
          _isLoading = false;
        });
      }
    }
  }

  void _openPdfPage(String? pdfUrl, String? pageRef) {
    HapticFeedback.lightImpact();

    if (pdfUrl != null && pdfUrl.isNotEmpty && pdfUrl.startsWith('http')) {
      final lower = pdfUrl.toLowerCase();
      if (lower.endsWith('.pdf') || lower.contains('drive.google.com')) {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: true,
            pageBuilder: (context, animation, secondaryAnimation) => PdfViewerScreen(
              pdfTitle: "${widget.subjectName} Solution Guide",
              pdfUrl: pdfUrl,
              pdfType: 'Note',
              subjectName: widget.subjectName,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(Tween(begin: const Offset(0.0, 1.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
                child: child,
              );
            },
          ),
        );
        return;
      } else {
        launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Clean, modern floating toast matching the app's design system
    final displayRef = pageRef?.isNotEmpty == true ? pageRef! : "Specified Page";
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Color(0xFF93C5FD),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                 mainAxisSize: MainAxisSize.min,
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     "Target: $displayRef",
                     style: const TextStyle(
                       fontWeight: FontWeight.w800,
                       fontFamily: 'Manrope',
                       fontSize: 13.5,
                       color: Colors.white,
                     ),
                   ),
                   const SizedBox(height: 2),
                   Text(
                     "Refer to ${widget.subjectName} notes in the Notes tab",
                     style: TextStyle(
                       fontWeight: FontWeight.w500,
                       fontFamily: 'Manrope',
                       fontSize: 11.5,
                       color: Colors.white.withValues(alpha: 0.8),
                     ),
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                   ),
                 ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.c.hero,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainer,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
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
                  child: Icon(CupertinoIcons.arrow_left, color: theme.colorScheme.onSurface, size: 18),
                ),
              ),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.colorScheme.outlineVariant, height: 1),
        ),
        title: Text(
          widget.subjectName,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            fontFamily: 'Manrope',
          ),
        ),
      ),
      body: _isLoading
          ? const ImpGuideSkeleton()
          : _guideData == null
              ? _buildEmptyState(theme)
              : _buildMasterGuideView(theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.c.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(CupertinoIcons.doc_text, size: 48, color: context.c.accent),
            ),
            const SizedBox(height: 20),
            Text(
              "IMP Guide Coming Soon!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Our team is analyzing past 5 years of exam papers for ${widget.subjectName}.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterGuideView(ThemeData theme) {
    final title = _guideData!['title'] as String? ?? '${widget.subjectCode} Master Guide';
    final rawStats = _guideData!['stats'] as List<dynamic>? ?? [];
    final rawModules = _guideData!['modules'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 🌟 Header Stats Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rawStats.map((st) {
                  final label = (st['label'] ?? '') as String;
                  Color? color;
                  if (st['color'] != null) {
                    try {
                      final hex = (st['color'] as String).replaceAll('#', '');
                      color = Color(int.parse('FF$hex', radix: 16));
                    } catch (_) {}
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (color ?? theme.colorScheme.onSurface).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: (color ?? theme.colorScheme.outlineVariant).withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color ?? theme.colorScheme.onSurface,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 📚 Modules List
        ...rawModules.asMap().entries.map((entry) {
          final int modIndex = entry.key;
          final Map<String, dynamic> mod = entry.value as Map<String, dynamic>;
          final String modTitle = mod['module_title'] ?? 'Module ${modIndex + 1}';
          final String? strategyTip = mod['strategy_tip'];
          final List<dynamic> topics = mod['topics'] ?? [];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: modIndex == 0,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.c.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "M${modIndex + 1}",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: context.c.accent),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        modTitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 💡 Master Strategy Box
                        if (strategyTip != null && strategyTip.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.c.warningSoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.c.warningBorder),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("💡", style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Master Strategy",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: context.c.warningText,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        strategyTip,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF78350F),
                                          height: 1.4,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Topics and Questions
                        ...topics.map((top) {
                          final String topicTitle = top['topic_title'] ?? '';
                          final List<dynamic> questions = top['questions'] ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                if (topicTitle.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(top: 1.0),
                                          child: Icon(Icons.label_important_outline, size: 14, color: context.c.accent),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            topicTitle.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: theme.colorScheme.onSurfaceVariant,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                              // Questions List
                              ...questions.map((q) => _buildQuestionItem(q, theme)),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQuestionItem(Map<String, dynamic> q, ThemeData theme) {
    final String questionText = q['question'] ?? '';
    final List<dynamic> badges = q['badges'] ?? [];
    final List<dynamic> examTags = q['exam_tags'] ?? [];
    final List<dynamic> recentTags = q['recent_tags'] ?? [];
    final String? pageRef = q['page_ref'];
    final String? pdfUrl = q['pdf_url'];
    final List<dynamic> subPoints = q['sub_points'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Text
          Text(
            questionText,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              height: 1.4,
              fontFamily: 'Manrope',
            ),
          ),

          // Sub Points
          if (subPoints.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...subPoints.map((pt) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• ", style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      pt.toString(),
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, height: 1.3),
                    ),
                  ),
                ],
              ),
            )),
          ],

          const SizedBox(height: 8),

          // Meta Row: Badges, Exam Tags, Page Button
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Badges
              ...badges.map((b) {
                final bStr = b.toString();
                Color bColor = context.c.tint(const Color(0xFF2563EB)); // blue default
                if (bStr.toLowerCase().contains('high') || bStr.toLowerCase().contains('top') || bStr.toLowerCase().contains('fire')) {
                  bColor = context.c.tint(const Color(0xFFDC2626));
                } else if (bStr.toLowerCase().contains('diagram') || bStr.toLowerCase().contains('draw')) {
                  bColor = context.c.tint(const Color(0xFF7C3AED));
                } else if (bStr.toLowerCase().contains('rare') || bStr.toLowerCase().contains('unique')) {
                  bColor = context.c.tint(const Color(0xFF0891B2));
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: bColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    bStr,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: bColor),
                  ),
                );
              }),

              // Exam Tags
              ...examTags.map((tag) {
                final tagStr = tag.toString();
                final isRecent = recentTags.contains(tagStr) || tagStr.contains('25') || tagStr.contains('24');

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isRecent ? const Color(0xFF10B981).withValues(alpha: 0.12) : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isRecent ? const Color(0xFF10B981).withValues(alpha: 0.3) : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    tagStr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isRecent ? context.c.pick(const Color(0xFF059669), const Color(0xFF34D399)) : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }),

              // Page Link Button
              if (pageRef != null && pageRef.isNotEmpty) ...[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openPdfPage(pdfUrl, pageRef),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: context.c.info.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book_rounded, size: 11, color: context.c.info),
                          const SizedBox(width: 4),
                          Text(
                            pageRef,
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: context.c.info),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Master Guide Detail View Skeleton Loader
// ─────────────────────────────────────────────
class ImpGuideSkeleton extends StatefulWidget {
  const ImpGuideSkeleton({super.key});

  @override
  State<ImpGuideSkeleton> createState() => _ImpGuideSkeletonState();
}

class _ImpGuideSkeletonState extends State<ImpGuideSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.35 + (_controller.value * 0.65),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card Skeleton
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 18,
                      width: 220,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(4, (i) => Container(
                        height: 26,
                        width: 85 + (i * 12.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      )),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Module Cards Skeleton
              ...List.generate(3, (modIndex) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Module Header Row
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 24,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Strategy Tip Box Skeleton
                    Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Questions Skeletons
                    ...List.generate(2, (qIndex) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 14,
                            width: 160,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                height: 18,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                height: 18,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}
