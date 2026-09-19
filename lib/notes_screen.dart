import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/analytics_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/skeleton_loaders.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:ai/services/recent_files_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'widgets/contribution_bottom_sheet.dart';
import 'widgets/premium_touch_button.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nirma Hub - Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: context.c.bg,
        fontFamily: 'Manrope',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC62828)),
        useMaterial3: true,
      ),
      home: const NotesScreen(),
    );
  }
}

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _searchQuery = "";
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;
  String _currentYear = "";

  IconData _getIconForSubject(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math') || lower.contains('stat')) return Icons.calculate;
    if (lower.contains('comput') || lower.contains('ai') || lower.contains('web') || lower.contains('prog')) return Icons.computer;
    if (lower.contains('electric') || lower.contains('ece') || lower.contains('circ')) return Icons.electrical_services;
    if (lower.contains('mech') || lower.contains('machine')) return Icons.settings;
    if (lower.contains('civil') || lower.contains('arch')) return Icons.architecture;
    if (lower.contains('chem') || lower.contains('bio') || lower.contains('pharma')) return Icons.science;
    if (lower.contains('phys')) return Icons.lightbulb_outline;
    if (lower.contains('env') || lower.contains('eco')) return Icons.eco;
    if (lower.contains('data') || lower.contains('algo') || lower.contains('dbms')) return Icons.account_tree;
    if (lower.contains('network') || lower.contains('cloud')) return Icons.router;
    if (lower.contains('eng') && !lower.contains('english')) return Icons.engineering;
    if (lower.contains('english') || lower.contains('comm')) return Icons.chat_bubble_outline;
    if (lower.contains('manage') || lower.contains('busi') || lower.contains('econ')) return Icons.trending_up;
    if (lower.contains('design') || lower.contains('draw')) return Icons.design_services;
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

  String _currentBranch = "";

  Future<void> _fetchSubjects(String rawAcademicYear, String userBranch) async {
    if (rawAcademicYear.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    if (mounted) setState(() => _isLoading = true);

    String academicYear = rawAcademicYear;
    if (academicYear.toLowerCase().contains("1st")) academicYear = "1st";
    else if (academicYear.toLowerCase().contains("2nd")) academicYear = "2nd";
    else if (academicYear.toLowerCase().contains("3rd")) academicYear = "3rd";
    else if (academicYear.toLowerCase().contains("4th")) academicYear = "4th";

    try {
      var query = Supabase.instance.client
          .from('subjects')
          .select('*')
          .eq('academic_year', academicYear);
          
      if (academicYear != '1st' && userBranch.isNotEmpty) {
        query = query.or('branch.eq.$userBranch,branch.eq.Common');
      }

      final response = await query;
      
      final mapped = (response as List<dynamic>).map((s) {
        final name = s['name'] as String;
        return {
          "id": s["id"],
          "name": name,
          "code": s["code"],
          "notes_special_thanks": s["notes_special_thanks"],
          "color": _getColorForSubject(name),
          "iconColor": _getIconColorForSubject(name),
          "icon": _getIconForSubject(name),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _subjects = mapped;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching subjects: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(authNotifierProvider).value;
    final academicYear = userProfile?.academicYear ?? '';
    final branch = userProfile?.branch ?? '';
    
    if ((academicYear != _currentYear || branch != _currentBranch) && academicYear.isNotEmpty) {
      _currentYear = academicYear;
      _currentBranch = branch;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchSubjects(academicYear, branch);
      });
    }

    

    final filteredSubjects = _subjects.where((s) {
      final nameLower = (s["name"] as String).toLowerCase();
      final codeLower = (s["code"] as String).toLowerCase();
      final queryLower = _searchQuery.toLowerCase().trim();

      // Create an acronym by taking the first letter of each word, ignoring common words
      final ignoreWords = {'and', 'for', 'to', 'in', 'of', 'the', 'a', 'an', 'or', '&'};
      final acronym = nameLower
          .split(RegExp(r'\s+'))
          .where((String word) => word.isNotEmpty && !ignoreWords.contains(word))
          .map((String word) => word[0])
          .join('');

      return nameLower.contains(queryLower) || 
             codeLower.contains(queryLower) || 
             acronym.contains(queryLower);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
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
          'Notes',
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
          ? const ListSkeleton() 
          : _subjects.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          "There are no Notes Uploaded for current year",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, fontFamily: 'Manrope'),
                        ),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _buildSearchBar(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final subject = filteredSubjects[index];
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
                          color: Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1.0),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            splashColor: const Color(0xFFC62828).withValues(alpha: 0.10),
                            highlightColor: const Color(0xFFC62828).withValues(alpha: 0.05),
                            onTap: () {
                              Future.delayed(const Duration(milliseconds: 120), () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => SubjectDetailsScreen(
                                      subjectId: subject["id"],
                                      subjectName: subject["name"], 
                                      subjectCode: subject["code"],
                                      specialThanks: subject["notes_special_thanks"] ?? 'Seniors',
                                    ),
                                  ),
                                );
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: subject["iconColor"].withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: subject["iconColor"].withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: Icon(subject["icon"], color: subject["iconColor"], size: 20),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subject["name"],
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          subject["code"],
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
          SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface, fontFamily: 'Manrope'),
      cursorColor: context.c.accent,
      decoration: InputDecoration(
        hintText: 'Search subjects or codes...',
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 15),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 22.0, right: 8.0),
          child: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        filled: true,
        fillColor: context.c.card,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

class SubjectDetailsScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String specialThanks;

  const SubjectDetailsScreen({
    super.key, 
    required this.subjectId, 
    required this.subjectName, 
    required this.subjectCode,
    required this.specialThanks,
  });

  @override
  State<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Map<String, dynamic> _getCategoryData(String folderType) {
    final lower = folderType.toLowerCase();
    
    // Legacy mapping and standard types
    if (lower == "ppts" || lower == "ppt") {
      return {"title": "PPTs", "folder_type": folderType, "icon": Icons.slideshow_rounded, "color": context.c.tint(const Color(0xFFEA580C)).withValues(alpha: 0.08), "iconColor": context.c.tint(const Color(0xFFEA580C)), "desc": "Lecture presentations"};
    }
    if (lower == "notes" || lower == "handwritten_notes" || lower == "handwritten notes") {
      return {"title": "Handwritten Notes", "folder_type": folderType, "icon": Icons.edit_note_rounded, "color": context.c.tint(const Color(0xFF2563EB)).withValues(alpha: 0.08), "iconColor": context.c.tint(const Color(0xFF2563EB)), "desc": "Notes by students"};
    }
    if (lower == "practicals" || lower == "practical") {
      return {"title": "Practicals", "folder_type": folderType, "icon": Icons.science_rounded, "color": context.c.tint(const Color(0xFF059669)).withValues(alpha: 0.08), "iconColor": context.c.tint(const Color(0xFF059669)), "desc": "Lab manuals & assignments"};
    }
    if (lower == "course_policy" || lower == "course policy" || lower == "policy") {
      return {"title": "Course Policy", "folder_type": folderType, "icon": Icons.policy_rounded, "color": context.c.tint(const Color(0xFF7C3AED)).withValues(alpha: 0.08), "iconColor": context.c.tint(const Color(0xFF7C3AED)), "desc": "Syllabus and grading"};
    }
    if (lower.contains("assignment")) {
      return {"title": folderType, "folder_type": folderType, "icon": Icons.assignment_rounded, "color": context.c.tint(const Color(0xFFD97706)).withValues(alpha: 0.08), "iconColor": context.c.tint(const Color(0xFFD97706)), "desc": "Course assignments"};
    }
    if (lower.contains("paper") || lower.contains("exam")) {
      return {"title": folderType, "folder_type": folderType, "icon": Icons.text_snippet_rounded, "color": context.c.accent.withValues(alpha: 0.08), "iconColor": context.c.accent, "desc": "Previous year papers"};
    }
    if (lower.contains("book") || lower.contains("reference")) {
      return {"title": folderType, "folder_type": folderType, "icon": Icons.library_books_rounded, "color": context.c.tint(const Color(0xFF0891B2)).withValues(alpha: 0.08), "iconColor": context.c.tint(const Color(0xFF0891B2)), "desc": "Reference materials"};
    }

    // Default dynamic style for completely custom categories
    return {
      "title": folderType,
      "folder_type": folderType,
      "icon": Icons.folder_rounded,
      "color": context.c.accent.withValues(alpha: 0.08),
      "iconColor": context.c.accent,
      "desc": "Subject materials"
    };
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('materials')
          .select('folder_type')
          .eq('subject_id', widget.subjectId);

      final uniqueTypes = (response as List<dynamic>)
          .map((row) => row['folder_type'] as String)
          .toSet()
          .toList();

      final mapped = uniqueTypes.map((type) => _getCategoryData(type)).toList();

      // Sort mapped to put PPTs, Notes, Practicals, Policy first, then alphabetically
      mapped.sort((a, b) {
        const order = {"PPTs": 1, "Handwritten Notes": 2, "Practicals": 3, "Course Policy": 4};
        final orderA = order[a["title"]] ?? 99;
        final orderB = order[b["title"]] ?? 99;
        if (orderA != orderB) return orderA.compareTo(orderB);
        return a["title"].toString().compareTo(b["title"].toString());
      });

      if (mounted) {
        setState(() {
          _categories = mapped;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSubjectInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SubjectInfoBottomSheet(
          subjectId: widget.subjectId,
          subjectName: widget.subjectName,
          subjectCode: widget.subjectCode,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 8,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        ),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subjectName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Manrope', letterSpacing: -0.5)),
            Text(widget.subjectCode, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurface, size: 24),
            onPressed: _showSubjectInfo,
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const ListSkeleton()
          : _categories.isEmpty
              ? Center(
                  child: Text(
                    "No materials uploaded yet.",
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final folderCard = Padding(
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
                            color: Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1.0),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              splashColor: const Color(0xFFC62828).withValues(alpha: 0.10),
                              highlightColor: const Color(0xFFC62828).withValues(alpha: 0.05),
                              onTap: () {
                                Future.delayed(const Duration(milliseconds: 120), () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => MaterialsListScreen(
                                        subjectId: widget.subjectId,
                                        folderType: cat["folder_type"],
                                        subjectName: widget.subjectName,
                                        categoryName: cat["title"],
                                      ),
                                    ),
                                  );
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: cat["color"],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: cat["iconColor"].withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: Icon(cat["icon"], color: cat["iconColor"], size: 20),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cat["title"],
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: Theme.of(context).colorScheme.onSurface,
                                              fontFamily: 'Manrope',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            cat["desc"],
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(CupertinoIcons.chevron_forward, color: context.c.borderStrong, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );

                    return folderCard;
                  },
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return ContributionBottomSheet(
                    subjectName: widget.subjectName,
                    specialThanks: widget.specialThanks,
                    isPyq: false,
                  );
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_rounded, color: Theme.of(context).colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Want Special Thanks?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MaterialsListScreen extends StatefulWidget {
  final String subjectId;
  final String folderType;
  final String subjectName;
  final String categoryName;

  const MaterialsListScreen({super.key, required this.subjectId, required this.folderType, required this.subjectName, required this.categoryName});

  @override
  State<MaterialsListScreen> createState() => _MaterialsListScreenState();
}

class _MaterialsListScreenState extends State<MaterialsListScreen> {
  List<Map<String, dynamic>> _materials = [];
  Set<String> _pinnedIds = {};
  bool _isLoading = true;
  String _selectedSort = 'rating'; // 'pinned', 'rating', 'latest', 'name'

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _loadPinnedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('pinned_material_ids') ?? [];
      if (mounted) {
        setState(() {
          _pinnedIds = list.toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchMaterials() async {
    try {
      await _loadPinnedIds();
      final response = await Supabase.instance.client
          .from('materials')
          .select('*')
          .eq('subject_id', widget.subjectId)
          .eq('folder_type', widget.folderType);

      if (mounted) {
        setState(() {
          _materials = List<Map<String, dynamic>>.from(response);
          _applySorting();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching materials: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePin(Map<String, dynamic> mat) async {
    final matId = mat['id']?.toString();
    if (matId == null || matId.isEmpty) return;

    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    final isPinned = _pinnedIds.contains(matId);

    setState(() {
      if (isPinned) {
        _pinnedIds.remove(matId);
      } else {
        _pinnedIds.add(matId);
      }
      _applySorting();
    });

    await prefs.setStringList('pinned_material_ids', _pinnedIds.toList());

    AnalyticsService.logMaterialInteraction(
      materialId: matId,
      fileName: mat['file_name'] ?? 'Document',
      interactionType: isPinned ? 'unpin' : 'pin',
      subjectName: widget.subjectName,
      folderType: widget.folderType,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                isPinned ? "Material unpinned" : "📌 Pinned to top of materials!",
                style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Manrope'),
              ),
            ],
          ),
          backgroundColor: isPinned ? context.c.textSecondary : const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  int _pinnedCountForCategory() {
    return _materials.where((m) => _pinnedIds.contains(m['id']?.toString() ?? '')).length;
  }

  void _applySorting() {
    _materials.sort((a, b) {
      final aId = a['id']?.toString() ?? '';
      final bId = b['id']?.toString() ?? '';
      final aPinned = _pinnedIds.contains(aId);
      final bPinned = _pinnedIds.contains(bId);

      // In non-pinned sort modes, pinned items always stay at the top
      if (aPinned != bPinned) {
        return aPinned ? -1 : 1;
      }

      if (_selectedSort == 'pinned') {
        return (b['file_date'] ?? '').toString().compareTo((a['file_date'] ?? '').toString());
      } else if (_selectedSort == 'rating') {
        final aAvg = (a['avg_rating'] as num?)?.toDouble() ?? 0.0;
        final bAvg = (b['avg_rating'] as num?)?.toDouble() ?? 0.0;
        final aCount = (a['rating_count'] as num?)?.toInt() ?? 0;
        final bCount = (b['rating_count'] as num?)?.toInt() ?? 0;
        if (aAvg != bAvg) return bAvg.compareTo(aAvg);
        if (aCount != bCount) return bCount.compareTo(aCount);
        return (b['file_date'] ?? '').toString().compareTo((a['file_date'] ?? '').toString());
      } else if (_selectedSort == 'latest') {
        return (b['file_date'] ?? '').toString().compareTo((a['file_date'] ?? '').toString());
      } else {
        return (a['file_name'] ?? '').toString().toLowerCase().compareTo((b['file_name'] ?? '').toString().toLowerCase());
      }
    });
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
    } catch (_) {
      return isoString;
    }
  }

  IconData _getFileIcon(String fileName, String folderType) {
    final name = fileName.toLowerCase();
    final folder = folderType.toLowerCase();
    if (name.endsWith('.pdf')) {
      if (folder.contains('ppt')) return Icons.slideshow_rounded;
      if (folder.contains('practical') || folder.contains('lab')) return Icons.science_rounded;
      if (folder.contains('note')) return Icons.edit_note_rounded;
      if (folder.contains('policy') || folder.contains('syllabus')) return Icons.policy_rounded;
      if (folder.contains('assignment')) return Icons.assignment_rounded;
      return Icons.picture_as_pdf_rounded;
    }
    if (name.endsWith('.ppt') || name.endsWith('.pptx')) return Icons.slideshow_rounded;
    if (name.endsWith('.doc') || name.endsWith('.docx')) return Icons.description_rounded;
    if (name.endsWith('.xls') || name.endsWith('.xlsx')) return Icons.table_chart_rounded;
    if (name.endsWith('.zip') || name.endsWith('.rar')) return Icons.folder_zip_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getFileColor(String fileName, String folderType, BuildContext context) {
    final name = fileName.toLowerCase();
    final folder = folderType.toLowerCase();
    if (folder.contains('ppt') || name.endsWith('.ppt') || name.endsWith('.pptx')) {
      return context.c.tint(const Color(0xFFEA580C)); // Warm Orange for PPTs
    }
    if (folder.contains('practical') || folder.contains('lab') || folder.contains('code')) {
      return context.c.tint(const Color(0xFF059669)); // Emerald Green for Practicals
    }
    if (folder.contains('note') || folder.contains('handwritten')) {
      return context.c.tint(const Color(0xFF2563EB)); // Royal Blue for Handwritten Notes
    }
    if (folder.contains('policy') || folder.contains('syllabus')) {
      return context.c.tint(const Color(0xFF7C3AED)); // Vibrant Purple for Course Policy
    }
    if (folder.contains('assignment')) {
      return context.c.tint(const Color(0xFFD97706)); // Amber for Assignments
    }
    return Theme.of(context).colorScheme.error; // Crimson Red for general PDFs / PYQs
  }

  void _openDocument(Map<String, dynamic> mat) {
    final urlStr = mat["drive_url"]?.toString() ?? '';
    final fileName = (mat["file_name"] as String? ?? '').toLowerCase();
    final isPdf = fileName.endsWith('.pdf');

    AnalyticsService.logMaterialInteraction(
      materialId: mat['id']?.toString() ?? '',
      fileName: mat['file_name'] ?? 'Document',
      interactionType: 'view',
      subjectName: widget.subjectName,
      folderType: widget.folderType,
    );

    if (urlStr.isNotEmpty) {
      if (isPdf) {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: true,
            pageBuilder: (context, animation, secondaryAnimation) => PdfViewerScreen(
              pdfTitle: mat["file_name"] != null && mat["file_name"].toString().isNotEmpty ? mat["file_name"] : (mat["title"] ?? "Document"),
              pdfUrl: urlStr,
              pdfType: 'Note',
              pdfTimestamp: mat["file_date"] != null ? DateTime.tryParse(mat["file_date"].toString()) : null,
              materialId: mat["id"]?.toString(),
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
      } else {
        launchUrl(
          Uri.parse(urlStr),
          mode: LaunchMode.inAppBrowserView,
        );
      }
    }
  }

  void _openActionsMenu(Map<String, dynamic> mat) {
    final matId = mat['id']?.toString() ?? '';
    final isPinned = _pinnedIds.contains(matId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MaterialActionsBottomSheet(
        material: mat,
        subjectName: widget.subjectName,
        isPinned: isPinned,
        onTogglePin: () => _togglePin(mat),
        onOpenRating: () => _openRatingSheet(mat),
        onOpenPdf: () => _openDocument(mat),
      ),
    );
  }

  void _openRatingSheet(Map<String, dynamic> mat) {
    final matId = mat['id']?.toString();
    if (matId == null || matId.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MaterialRatingBottomSheet(
        materialId: matId,
        materialTitle: mat['file_name'] ?? 'Study Material',
        subjectName: widget.subjectName,
        onRatingSubmitted: (newAvg, newCount) {
          if (mounted) {
            setState(() {
              mat['avg_rating'] = newAvg;
              mat['rating_count'] = newCount;
              _applySorting();
            });
          }
        },
      ),
    );
  }

  Widget _buildSortChip(String label, String sortKey) {
    final isSelected = _selectedSort == sortKey;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (_selectedSort != sortKey) {
          setState(() {
            _selectedSort = sortKey;
            _applySorting();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontFamily: 'Manrope',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayMaterials = _selectedSort == 'pinned'
        ? _materials.where((m) => _pinnedIds.contains(m['id']?.toString() ?? '')).toList()
        : _materials;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 8,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        ),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.categoryName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Manrope', letterSpacing: -0.5)),
            Text(widget.subjectName, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      ),
      body: _isLoading 
        ? const ListSkeleton()
        : _materials.isEmpty 
          ? Center(
              child: Text(
                "No materials found.",
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
            )
          : Column(
              children: [
                // Sort Controls Bar (Horizontal Scrollable)
                if (_materials.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: Row(
                      children: [
                        Text(
                          "Sort:",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildSortChip(
                          _pinnedCountForCategory() > 0 
                              ? "Pinned (${_pinnedCountForCategory()})" 
                              : "Pinned", 
                          'pinned',
                        ),
                        const SizedBox(width: 6),
                        _buildSortChip("Top Rated", 'rating'),
                        const SizedBox(width: 6),
                        _buildSortChip("Latest", 'latest'),
                        const SizedBox(width: 6),
                        _buildSortChip("Name", 'name'),
                      ],
                    ),
                  ),

                Expanded(
                  child: displayMaterials.isEmpty && _selectedSort == 'pinned'
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: context.c.warningSoft,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(Icons.push_pin_outlined, color: context.c.pick(const Color(0xFFD97706), const Color(0xFFFBBF24)), size: 30),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No Pinned Materials",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Tap ⋯ on any note and select 'Pin to Top' for instant quick access during exams.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                          itemCount: displayMaterials.length,
                          itemBuilder: (context, index) {
                            final mat = displayMaterials[index];
                            final matId = mat['id']?.toString() ?? '';
                            final isPinned = _pinnedIds.contains(matId);

                            final fileName = (mat["file_name"] as String? ?? '').toLowerCase();
                            final fileIcon = _getFileIcon(fileName, widget.folderType);
                            final fileColor = _getFileColor(fileName, widget.folderType, context);

                            final avgRating = (mat['avg_rating'] is num) 
                                ? (mat['avg_rating'] as num).toDouble() 
                                : (double.tryParse(mat['avg_rating']?.toString() ?? '') ?? 0.0);
                            final ratingCount = (mat['rating_count'] is num) 
                                ? (mat['rating_count'] as num).toInt() 
                                : (int.tryParse(mat['rating_count']?.toString() ?? '') ?? 0);
                            final isExamSaver = avgRating >= 4.7 && ratingCount >= 3;
                            
                            final matCard = PremiumTouchButton(
                              enableRipple: false,
                              child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isPinned
                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                                      : isExamSaver 
                                          ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                                          : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), 
                                  width: isPinned || isExamSaver ? 1.4 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isPinned
                                        ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                                        : isExamSaver 
                                            ? const Color(0xFFF59E0B).withValues(alpha: 0.05)
                                            : context.c.shadow.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  splashColor: const Color(0xFFC62828).withValues(alpha: 0.10),
                                  highlightColor: const Color(0xFFC62828).withValues(alpha: 0.05),
                                  onTap: () {
                                    Future.delayed(const Duration(milliseconds: 120), () {
                                      _openDocument(mat);
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42, height: 42,
                                          decoration: BoxDecoration(
                                            color: fileColor.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: fileColor.withValues(alpha: 0.15)),
                                          ),
                                          child: Icon(
                                            fileIcon,
                                            color: fileColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                mat["file_name"] ?? '',
                                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, fontFamily: 'Manrope'),
                                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: [
                                                  // 📌 Pinned Badge
                                                  if (isPinned)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: context.c.warningSoft,
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: context.c.pick(const Color(0xFFFCD34D), const Color(0xFF5C4413))),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.push_pin_rounded, size: 11, color: context.c.pick(const Color(0xFFD97706), const Color(0xFFFBBF24))),
                                                          SizedBox(width: 3),
                                                          Text(
                                                            "PINNED",
                                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: context.c.pick(const Color(0xFFD97706), const Color(0xFFFBBF24)), fontFamily: 'Manrope'),
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                  // ⚡ EXAM SAVER Badge
                                                  if (isExamSaver)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        gradient: const LinearGradient(
                                                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                                        ),
                                                        borderRadius: BorderRadius.circular(8),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 1),
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.bolt_rounded, size: 12, color: Colors.white),
                                                          SizedBox(width: 2),
                                                          Text(
                                                            "EXAM SAVER",
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w900,
                                                              color: Colors.white,
                                                              fontFamily: 'Manrope',
                                                              letterSpacing: 0.3,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                  // 5-Star Rating Pill (Small inline)
                                                  if (ratingCount > 0)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: context.c.warningSoft,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                                                          const SizedBox(width: 2),
                                                          Text(
                                                            avgRating.toStringAsFixed(1),
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w900,
                                                              color: context.c.pick(const Color(0xFF92400E), const Color(0xFFFCD34D)),
                                                              fontFamily: 'Manrope',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                  Text(
                                                    _formatDate(mat["file_date"] ?? ''), 
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                                  ),

                                                  // Total pages badge
                                                  if (mat["total_pages"] != null && (int.tryParse(mat["total_pages"].toString()) ?? 0) > 0)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                      decoration: BoxDecoration(
                                                        color: fileColor.withValues(alpha: 0.08),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.menu_book_rounded, size: 11, color: fileColor),
                                                          const SizedBox(width: 3),
                                                          Text(
                                                            "${mat["total_pages"]} pgs",
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w800,
                                                              color: fileColor,
                                                              fontFamily: 'Manrope',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Trailing Section with File Size & 3-Dots Button
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (mat["file_size"] != null) ...[
                                              Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Icon(Icons.download_rounded, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "${(mat["file_size"] / 1024 / 1024).toStringAsFixed(1)} MB",
                                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                            // 3-Dots More Actions Menu Button
                                            Material(
                                              color: Colors.transparent,
                                              shape: const CircleBorder(),
                                              clipBehavior: Clip.antiAlias,
                                              child: InkWell(
                                                onTap: () => _openActionsMenu(mat),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(6.0),
                                                  child: Icon(
                                                    Icons.more_vert_rounded,
                                                    size: 20,
                                                    color: isPinned 
                                                        ? context.c.pick(const Color(0xFFD97706), const Color(0xFFFBBF24)) 
                                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ));

                            return matCard;
                          },
                        ),
                ),
                const SizedBox(height: 8),
              ],
            ),
    );
  }
}

class SubjectInfoBottomSheet extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String tableName;

  const SubjectInfoBottomSheet({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    this.tableName = 'materials',
  });

  @override
  State<SubjectInfoBottomSheet> createState() => _SubjectInfoBottomSheetState();
}

class _SubjectInfoBottomSheetState extends State<SubjectInfoBottomSheet> {
  bool _isLoading = true;
  double _totalSizeMB = 0;
  List<File> _cachedFiles = [];

  @override
  void initState() {
    super.initState();
    _calculateStorage();
  }

  Future<void> _calculateStorage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Fetch all materials for this subject
      final response = await Supabase.instance.client
          .from(widget.tableName)
          .select('drive_url, file_name')
          .eq('subject_id', widget.subjectId);

      final dir = await getApplicationDocumentsDirectory();
      double size = 0;
      List<File> foundFiles = [];

      // 2. Extract file IDs and check files
      for (var row in response) {
        final url = row['drive_url'] as String;
        final fileName = row['file_name'] as String? ?? "";
        final parts = fileName.split('.');
        final ext = parts.length > 1 ? parts.last.toLowerCase() : 'pdf';

        String fileId = "unknown";
        if (url.contains('drive.google.com/file/d/')) {
          final RegExp regExp = RegExp(r'file/d/([a-zA-Z0-9_-]+)');
          final match = regExp.firstMatch(url);
          if (match != null && match.groupCount >= 1) {
            fileId = match.group(1)!;
          }
        } else if (url.contains('drive.google.com/open?id=')) {
          final Uri uri = Uri.parse(url);
          fileId = uri.queryParameters['id'] ?? "unknown";
        }

        if (fileId != "unknown") {
          final file = File('${dir.path}/file_$fileId.$ext');
          if (await file.exists()) {
            size += await file.length();
            foundFiles.add(file);
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalSizeMB = size / (1024 * 1024);
          _cachedFiles = foundFiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error calculating storage: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearCache() async {
    for (var file in _cachedFiles) {
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _calculateStorage(); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            // Drag handle
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            SizedBox(height: 16),
            
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.c.dangerSoft, // Light theme red
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.menu_book_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.subjectName, 
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, height: 1.2),
                              ),
                              SizedBox(height: 6),
                              Text(
                                widget.subjectCode, 
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 36),
                    
                    // About Section (Structured with bullet points)
                    Text("About Materials", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                    SizedBox(height: 20),
                    _buildInfoRow(
                      Icons.groups_rounded, 
                      "Community Driven", 
                      "Notes and materials are crowdsourced by students and the Nirma Hub community."
                    ),
                    SizedBox(height: 20),
                    _buildInfoRow(
                      Icons.school_rounded, 
                      "Educational Use", 
                      "Documents are for reference only. Copyrights belong to their respective creators."
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Disclaimer Box
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.c.warningSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.c.pick(const Color(0xFFFFEDD5), const Color(0xFF5C4413))),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: Color(0xFFEA580C), size: 24),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Disclaimer", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.c.pick(const Color(0xFF9A3412), const Color(0xFFFDBA74)))),
                                SizedBox(height: 6),
                                Text(
                                  "These notes do not guarantee full marks. Please refer to official university textbooks for comprehensive preparation.", 
                                  style: TextStyle(fontSize: 14, color: context.c.pick(const Color(0xFF9A3412), const Color(0xFFFDBA74)), height: 1.5, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 36),
                    
                    // Storage Section
                    Text("Device Storage", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                    SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainer),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.folder_zip_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 22),
                                  SizedBox(width: 10),
                                  Text("Cached PDFs", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.c.textSecondary)),
                                ],
                              ),
                              _isLoading
                                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                                  : Text(
                                      "${_totalSizeMB.toStringAsFixed(2)} MB", 
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                                    ),
                            ],
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: (_isLoading || _cachedFiles.isEmpty) ? null : _clearCache,
                              icon: Icon(Icons.delete_sweep_rounded, size: 20),
                              label: Text("Clear Subject Cache", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              style: FilledButton.styleFrom(
                                backgroundColor: context.c.accentSoft,
                                foregroundColor: context.c.pick(const Color(0xFFDC2626), const Color(0xFFF87171)),
                                disabledBackgroundColor: context.c.bg,
                                disabledForegroundColor: context.c.textFaint,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: context.c.textSecondary, size: 22),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.c.textSoft)),
              SizedBox(height: 6),
              Text(
                description, 
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String pdfTitle;
  final String pdfUrl;
  final String pdfType;
  final DateTime? pdfTimestamp;
  final String? materialId;
  final String? subjectName;

  const PdfViewerScreen({
    super.key,
    required this.pdfTitle,
    required this.pdfUrl,
    this.pdfType = 'Material',
    this.pdfTimestamp,
    this.materialId,
    this.subjectName,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> with WidgetsBindingObserver {
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  final PdfViewerController _pdfViewController = PdfViewerController();
  String? _localPdfPath;
  double _downloadProgress = 0.0;
  bool _isDownloading = true;
  String? _errorMessage;
  final ValueNotifier<bool> _showAppBar = ValueNotifier(true);
  final ValueNotifier<bool> _isScrolling = ValueNotifier(false);
  Timer? _hideTimer;
  PdfTextSearcher? _textSearcher;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchMode = false;

  @override
  void dispose() {
    AnalyticsService.endPdfSession();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    _pdfViewController.removeListener(_onPdfChanged);
    _hideTimer?.cancel();
    _searchController.dispose();
    _textSearcher?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AnalyticsService.startPdfSession(widget.pdfTitle);
    _downloadAndSavePdf();
    _pdfViewController.addListener(_onPdfChanged);
    
    _showAppBar.addListener(() {
      if (_showAppBar.value) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom]);
      }
    });
    
    // Log to recent files
    RecentFilesService.addRecentFile(RecentFile(
      title: widget.pdfTitle,
      url: widget.pdfUrl,
      type: widget.pdfType,
      timestamp: widget.pdfTimestamp ?? DateTime.now(),
    ));
  }

  void _onPdfChanged() {
    if (_pdfViewController.isReady) {
      final top = _pdfViewController.visibleRect.top;
      if (top <= 10.0 && !_showAppBar.value) {
        _showAppBar.value = true;
      } else if (top > 10.0 && _showAppBar.value) {
        _showAppBar.value = false;
      }
    }
  }

  Future<void> _downloadAndSavePdf() async {
    try {
      final url = _getDirectDownloadUrl(widget.pdfUrl);
      
      String fileId = "unknown";
      if (widget.pdfUrl.contains('drive.google.com/file/d/')) {
        final RegExp regExp = RegExp(r'file/d/([a-zA-Z0-9_-]+)');
        final match = regExp.firstMatch(widget.pdfUrl);
        if (match != null && match.groupCount >= 1) {
          fileId = match.group(1)!;
        }
      } else if (widget.pdfUrl.contains('drive.google.com/open?id=')) {
        final Uri uri = Uri.parse(widget.pdfUrl);
        fileId = uri.queryParameters['id'] ?? "unknown";
      }

      if (fileId == "unknown") {
        // Use a safe hash string for non-drive URLs so they don't overwrite each other
        fileId = base64UrlEncode(utf8.encode(widget.pdfUrl)).replaceAll('=', '');
        // Keep it reasonably short
        if (fileId.length > 50) {
          fileId = fileId.substring(fileId.length - 50);
        }
      }

      final parts = widget.pdfTitle.split('.');
      final ext = parts.length > 1 ? parts.last.toLowerCase() : 'pdf';
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/file_$fileId.$ext');

      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _localPdfPath = file.path;
            _isDownloading = false;
          });
        }
        return;
      }

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to load file. Status Code: ${response.statusCode}');
      }

      final contentLength = response.contentLength;
      
      int downloadedBytes = 0;
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (contentLength != null && contentLength > 0) {
          if (mounted) {
            setState(() {
              _downloadProgress = downloadedBytes / contentLength;
            });
          }
        }
      }
      
      await sink.close();

      if (mounted) {
        setState(() {
          _localPdfPath = file.path;
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isDownloading = false;
        });
      }
    }
  }

  String _getDirectDownloadUrl(String url) {
    if (url.contains('drive.google.com/file/d/')) {
      final RegExp regExp = RegExp(r'file/d/([a-zA-Z0-9_-]+)');
      final match = regExp.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        final fileId = match.group(1);
        return 'https://drive.google.com/uc?export=download&id=$fileId&confirm=t';
      }
    } else if (url.contains('drive.google.com/open?id=')) {
      final Uri uri = Uri.parse(url);
      final fileId = uri.queryParameters['id'];
      if (fileId != null) {
        return 'https://drive.google.com/uc?export=download&id=$fileId&confirm=t';
      }
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    const driveDark = Color(0xFF1A1C1E); // Google Drive Dark
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: driveDark,
        body: Stack(
        children: [
            Stack(
              children: [
          if (_isDownloading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Opening document...",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  if (_downloadProgress > 0) ...[
                    SizedBox(height: 8),
                    Text(
                      "${(_downloadProgress * 100).toInt()}%",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                    ),
                  ]
                ],
              ),
            )
          else if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.white70, size: 48),
                  SizedBox(height: 16),
                  Text(
                    "Unable to open document",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _errorMessage ?? "Unknown error",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _isDownloading = true;
                        _downloadProgress = 0.0;
                      });
                      _downloadAndSavePdf();
                    },
                    icon: Icon(Icons.refresh, color: Colors.blueAccent),
                    label: Text("Retry", style: TextStyle(color: Colors.blueAccent, fontSize: 16)),
                  )
                ],
              ),
            )
          else if (_localPdfPath != null)
            Listener(
              onPointerMove: (PointerMoveEvent event) {
                if (!_isScrolling.value) {
                  _isScrolling.value = true;
                }
                
                _hideTimer?.cancel();
                _hideTimer = Timer(const Duration(milliseconds: 1500), () {
                  if (mounted) _isScrolling.value = false;
                });
              },
              child: ValueListenableBuilder<bool>(
                valueListenable: _showAppBar,
                builder: (context, showAppBar, child) {
                  return AnimatedPadding(
                    padding: EdgeInsets.only(top: showAppBar ? 64.0 + topPadding : 0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: child!,
                  );
                },
                child: PdfViewer.file(
                  _localPdfPath!,
                  controller: _pdfViewController,
                  params: PdfViewerParams(
                      errorBannerBuilder: (context, error, stackTrace, documentRef) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, color: context.c.danger, size: 64),
                                const SizedBox(height: 16),
                                const Text(
                                  "Failed to open as PDF.",
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "The file might require permissions or isn't a valid PDF.",
                                  style: TextStyle(color: Colors.white70, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    launchUrl(Uri.parse(widget.pdfUrl), mode: LaunchMode.externalApplication);
                                  },
                                  icon: const Icon(Icons.open_in_browser),
                                  label: const Text("Open in Browser"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    backgroundColor: driveDark,
                    scrollPhysics: const BouncingScrollPhysics(),
                    pageDropShadow: BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 2, offset: Offset(2, 2)),
                    pagePaintCallbacks: [
                      (canvas, pageRect, page) {
                        _textSearcher?.pageTextMatchPaintCallback(canvas, pageRect, page);
                      }
                    ],

                    // By returning 0 (an invalid page) for all PDFs, we prevent pdfrx from automatically
                    // scrolling down to the first page's bounding box on load, which can cause 
                    // incorrect positioning and zoom due to early layout calculations.
                    calculateInitialPageNumber: (document, controller) => 0,
                    onViewerReady: (document, controller) {
                      if (document.pages.length == 1) {
                        // For 1-page PDFs, safely center them after the layout is fully built
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (controller.isReady) {
                            controller.goToPage(pageNumber: 1);
                          }
                        });
                      }
                    },
                viewerOverlayBuilder: (context, size, handleLinkTap) => [
                  PdfViewerScrollThumb(
                    controller: _pdfViewController,
                    orientation: ScrollbarOrientation.right,
                    thumbSize: const Size(100, 48), // Wider to fit both page pill and scroll handle
                    thumbBuilder: (context, thumbSize, pageNumber, controller) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: _isScrolling,
                        builder: (context, isScrolling, child) {
                          return AnimatedOpacity(
                            opacity: isScrolling ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_totalPages > 1) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2F33).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "${pageNumber ?? 1}/$_totalPages",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                            ],
                            Container(
                              width: 32,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2F33).withValues(alpha: 0.9),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.unfold_more,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      );
                        },
                      );
                    },
                  ),
                ],
                onPageChanged: (pageNumber) {
                  setState(() {
                    _currentPage = (pageNumber ?? 1) - 1;
                    _isReady = true;
                  });
                },
                onDocumentChanged: (document) {
                  if (document != null) {
                    setState(() {
                      if (_textSearcher == null && _pdfViewController.isReady) {
                        _textSearcher = PdfTextSearcher(_pdfViewController);
                      }
                      _totalPages = document.pages.length;
                      _isReady = true;
                    });
                  }
                },
              ),
              ),
            ),
          ),
        ],
      ),
      ValueListenableBuilder<bool>(
        valueListenable: _showAppBar,
        builder: (context, showAppBar, child) {
          return Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              offset: showAppBar ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AppBar(
                toolbarHeight: 64,
                backgroundColor: driveDark.withValues(alpha: 0.95),
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.white),
                titleSpacing: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  onPressed: () {
                    if (_isSearchMode) {
                      setState(() {
                        _isSearchMode = false;
                        _searchController.clear();
                        _textSearcher?.resetTextSearch();
                      });
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                title: _isSearchMode
                  ? TextField(
                      controller: _searchController,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      autofocus: true,
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: 'Search in document...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear, color: Colors.white, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _textSearcher?.resetTextSearch();
                          },
                        ),
                      ),
                      onChanged: (text) {
                        _textSearcher?.startTextSearch(text, searchImmediately: false);
                      },
                      onSubmitted: (_) async {
                        if (_textSearcher?.hasMatches == true) {
                          await _textSearcher!.goToNextMatch();
                          _textSearcher!.notifyListeners();
                        }
                      },
                    )
                  : Text(
                      widget.pdfTitle,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    ),
                actions: _isSearchMode
                  ? [
                      if (_textSearcher != null)
                        ListenableBuilder(
                          listenable: _textSearcher!,
                          builder: (context, child) {
                            return Row(
                              children: [
                                Text(
                                  _textSearcher!.hasMatches
                                      ? '${(_textSearcher!.currentIndex ?? 0) + 1}/${_textSearcher!.matches.length}'
                                      : '0/0',
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                IconButton(
                                  icon: Icon(Icons.keyboard_arrow_up, color: Colors.white),
                                  onPressed: _textSearcher!.hasMatches ? () async {
                                    await _textSearcher!.goToPrevMatch();
                                    _textSearcher!.notifyListeners();
                                  } : null,
                                ),
                                IconButton(
                                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                  onPressed: _textSearcher!.hasMatches ? () async {
                                    await _textSearcher!.goToNextMatch();
                                    _textSearcher!.notifyListeners();
                                  } : null,
                                ),
                              ],
                            );
                          }
                        ),
                      SizedBox(width: 8),
                    ]
                  : [
                      if (widget.materialId != null && widget.materialId!.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 24),
                          tooltip: 'Rate this Study Material',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => MaterialRatingBottomSheet(
                                materialId: widget.materialId!,
                                materialTitle: widget.pdfTitle,
                              ),
                            );
                          },
                        ),
                      IconButton(
                        icon: Icon(Icons.find_in_page_outlined, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isSearchMode = true;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.share, color: Colors.white),
                        onPressed: () {
                          if (widget.materialId != null && widget.materialId!.isNotEmpty) {
                            AnalyticsService.logMaterialInteraction(
                              materialId: widget.materialId!,
                              fileName: widget.pdfTitle,
                              interactionType: 'share',
                              subjectName: widget.subjectName,
                              folderType: widget.pdfType,
                            );
                          }
                          final buffer = StringBuffer();
                          buffer.writeln('📚 *Study Material Shared from Nirma Hub*');
                          buffer.writeln();
                          buffer.writeln('📄 *File:* ${widget.pdfTitle}');
                          if (widget.subjectName != null && widget.subjectName!.isNotEmpty) {
                            buffer.writeln('📖 *Subject:* ${widget.subjectName}');
                          }
                          buffer.writeln();
                          buffer.writeln('🚀 Download the Nirma Hub app for full notes, PYQs & exam prep:');
                          buffer.write('https://play.google.com/store/apps/details?id=com.ewrone.nirmahub');
                          Share.share(buffer.toString());
                        },
                      ),
                      SizedBox(width: 8),
                    ],
              ),
            ),
          );
        },
        ),
      ],
        ),
      ),
    );
  }
}

class MaterialRatingBottomSheet extends StatefulWidget {
  final String materialId;
  final String materialTitle;
  final String? subjectName;
  final Function(double newAvg, int newCount)? onRatingSubmitted;

  const MaterialRatingBottomSheet({
    super.key,
    required this.materialId,
    required this.materialTitle,
    this.subjectName,
    this.onRatingSubmitted,
  });

  @override
  State<MaterialRatingBottomSheet> createState() => _MaterialRatingBottomSheetState();
}

class _MaterialRatingBottomSheetState extends State<MaterialRatingBottomSheet> {
  int _selectedRating = 5;
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;
  bool _isLoadingExisting = true;
  bool _hasRatedBefore = false;

  final List<String> _availableTags = [
    "💯 Exam Saver",
    "✍️ Clean Handwriting",
    "🎯 Concise & Clear",
    "📐 Great Diagrams",
    "💎 Must Read",
    "📖 Complete Syllabus",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserExistingRating();
  }

  Future<String> _getUserId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.id.isNotEmpty) return user.id;
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('student_device_uuid');
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = 'anon_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
      await prefs.setString('student_device_uuid', deviceId);
    }
    return deviceId;
  }

  Future<void> _loadUserExistingRating() async {
    try {
      final userId = await _getUserId();
      final res = await Supabase.instance.client
          .from('material_ratings')
          .select('rating, tags')
          .eq('material_id', widget.materialId)
          .eq('user_id', userId)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          _selectedRating = (res['rating'] as num?)?.toInt() ?? 5;
          if (res['tags'] is List) {
            _selectedTags.clear();
            _selectedTags.addAll(List<String>.from(res['tags']));
          }
          _hasRatedBefore = true;
          _isLoadingExisting = false;
        });
        return;
      }
    } catch (e) {
      debugPrint("Error checking previous rating: $e");
    }
    if (mounted) {
      setState(() => _isLoadingExisting = false);
    }
  }

  String _getRatingFeedbackText(int rating) {
    switch (rating) {
      case 1:
        return "Needs Improvement 😕";
      case 2:
        return "Fair / Average 😐";
      case 3:
        return "Good Resource 🙂";
      case 4:
        return "Very Helpful! 😃";
      case 5:
      default:
        return "Absolute Exam Saver! 🔥";
    }
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);
    try {
      final userId = await _getUserId();
      final userEmail = Supabase.instance.client.auth.currentUser?.email;

      await Supabase.instance.client.from('material_ratings').upsert({
        'material_id': widget.materialId,
        'user_id': userId,
        'user_email': userEmail,
        'rating': _selectedRating,
        'tags': _selectedTags,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'material_id,user_id');

      // Fetch freshly computed stats from materials
      double newAvg = _selectedRating.toDouble();
      int newCount = 1;

      try {
        final matStats = await Supabase.instance.client
            .from('materials')
            .select('avg_rating, rating_count')
            .eq('id', widget.materialId)
            .maybeSingle();

        if (matStats != null && matStats['avg_rating'] != null) {
          newAvg = (matStats['avg_rating'] as num).toDouble();
          newCount = (matStats['rating_count'] as num?)?.toInt() ?? 1;
        }
      } catch (_) {}

      widget.onRatingSubmitted?.call(newAvg, newCount);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  _hasRatedBefore ? "Rating updated! Thank you ⭐" : "Thanks for rating this resource! ⭐",
                  style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Manrope'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error submitting rating: $e");
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error submitting rating: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.c.warningSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.c.pick(const Color(0xFFFCD34D), const Color(0xFF5C4413))),
                    ),
                    child: Icon(Icons.star_rounded, color: context.c.pick(const Color(0xFFD97706), const Color(0xFFFBBF24)), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasRatedBefore ? "Edit Resource Rating" : "Rate this Study Material",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontFamily: 'Manrope',
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.materialTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                ],
              ),
              const SizedBox(height: 24),

              // 5 Golden Interactive Stars
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final starNum = index + 1;
                    final isFilled = starNum <= _selectedRating;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedRating = starNum);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: AnimatedScale(
                          scale: isFilled ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 40,
                            color: isFilled ? const Color(0xFFF59E0B) : context.c.borderStrong,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),

              // Feedback Label Text
              Center(
                child: Text(
                  _getRatingFeedbackText(_selectedRating),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.c.pick(const Color(0xFFD97706), const Color(0xFFFBBF24)),
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Quick Feedback Tags Section
              Text(
                "Quick feedback tags (Optional):",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4) 
                          : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'Manrope',
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 26),

              // Submit Rating Button
              FilledButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: FilledButton.styleFrom(
                  backgroundColor: context.c.accentFill,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        _hasRatedBefore ? "Update Rating" : "Submit Rating",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Manrope'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MaterialActionsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> material;
  final String subjectName;
  final bool isPinned;
  final VoidCallback onTogglePin;
  final VoidCallback onOpenRating;
  final VoidCallback onOpenPdf;

  const MaterialActionsBottomSheet({
    super.key,
    required this.material,
    required this.subjectName,
    required this.isPinned,
    required this.onTogglePin,
    required this.onOpenRating,
    required this.onOpenPdf,
  });

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = material["file_name"] ?? 'Document';
    final totalPages = material["total_pages"];
    final fileDate = material["file_date"] != null ? _formatDate(material["file_date"].toString()) : '';
    final avgRating = (material['avg_rating'] is num)
        ? (material['avg_rating'] as num).toDouble()
        : (double.tryParse(material['avg_rating']?.toString() ?? '') ?? 0.0);
    final ratingCount = (material['rating_count'] is num)
        ? (material['rating_count'] as num).toInt()
        : (int.tryParse(material['rating_count']?.toString() ?? '') ?? 0);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 14.0, bottom: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // File Summary Card (Apple Style Preview)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.c.accentFill.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.c.accent.withValues(alpha: 0.18)),
                      ),
                      child: Icon(Icons.picture_as_pdf_rounded, color: context.c.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "$subjectName • $fileDate${totalPages != null ? ' • $totalPages pgs' : ''}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action List Container (Apple Grouped Style)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    // Action 1: 📌 Pin to Top / Unpin from Top
                    _buildActionTile(
                      context,
                      icon: isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                      iconColor: isPinned ? context.c.pick(const Color(0xFFD97706), const Color(0xFFFBBF24)) : Theme.of(context).colorScheme.onSurface,
                      iconBg: isPinned ? context.c.warningSoft : Theme.of(context).colorScheme.surface,
                      title: isPinned ? "Unpin from Top" : "Pin to Top of Materials",
                      subtitle: isPinned ? "Remove from sticky priority" : "Lock to the top of list for instant access",
                      trailingBadge: isPinned ? "Pinned" : null,
                      onTap: () {
                        Navigator.pop(context);
                        onTogglePin();
                      },
                      isFirst: true,
                    ),

                    _buildDivider(context),

                    // Action 2: ⭐ Rate this Material
                    _buildActionTile(
                      context,
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      iconBg: context.c.warningSoft,
                      title: "Rate this Study Material",
                      subtitle: ratingCount > 0 
                          ? "Currently rated ★ ${avgRating.toStringAsFixed(1)} ($ratingCount ratings)"
                          : "Give feedback to help fellow students",
                      onTap: () {
                        Navigator.pop(context);
                        onOpenRating();
                      },
                    ),

                    _buildDivider(context),

                    // Action 3: 🔗 Share Document
                    _buildActionTile(
                      context,
                      icon: Icons.share_rounded,
                      iconColor: context.c.info,
                      iconBg: context.c.infoSoft,
                      title: "Share Document",
                      subtitle: "Share with classmates via WhatsApp & apps",
                      onTap: () {
                        Navigator.pop(context);
                        AnalyticsService.logMaterialInteraction(
                          materialId: material['id']?.toString() ?? '',
                          fileName: fileName,
                          interactionType: 'share',
                          subjectName: subjectName,
                          folderType: material['folder_type']?.toString(),
                        );
                        final buffer = StringBuffer();
                        buffer.writeln('📚 *Study Material Shared from Nirma Hub*');
                        buffer.writeln();
                        buffer.writeln('📄 *File:* $fileName');
                        if (subjectName.isNotEmpty) {
                          buffer.writeln('📖 *Subject:* $subjectName');
                        }
                        buffer.writeln();
                        buffer.writeln('🚀 Download the Nirma Hub app for full notes, PYQs & exam prep:');
                        buffer.write('https://play.google.com/store/apps/details?id=com.ewrone.nirmahub');
                        Share.share(buffer.toString());
                      },
                    ),

                    _buildDivider(context),

                    // Action 4: 📖 Open & View
                    _buildActionTile(
                      context,
                      icon: Icons.open_in_new_rounded,
                      iconColor: context.c.pick(const Color(0xFF059669), const Color(0xFF34D399)),
                      iconBg: context.c.successSoft,
                      title: "Open & View Document",
                      subtitle: "Read PDF with built-in search and pages",
                      onTap: () {
                        Navigator.pop(context);
                        onOpenPdf();
                      },
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    String? trailingBadge,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.c.warningSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.c.pick(const Color(0xFFFCD34D), const Color(0xFF5C4413))),
                  ),
                  child: Text(
                    trailingBadge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: context.c.pick(const Color(0xFF92400E), const Color(0xFFFCD34D)),
                      fontFamily: 'Manrope',
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 68,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}
