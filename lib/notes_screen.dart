import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/skeleton_loaders.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:ai/services/recent_files_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'widgets/contribution_bottom_sheet.dart';
import 'widgets/premium_touch_button.dart';

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
        scaffoldBackgroundColor: const Color(0xFFF1F4F9),
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
    final colors = [
      const Color(0xFFE8F5E9), const Color(0xFFE3F2FD), const Color(0xFFF3E5F5),
      const Color(0xFFFFF3E0), const Color(0xFFFFF8E1), const Color(0xFFE0F7FA),
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
    return colors[hash % colors.length];
  }

  Future<void> _fetchSubjects(String rawAcademicYear) async {
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
      final response = await Supabase.instance.client
          .from('subjects')
          .select('*')
          .eq('academic_year', academicYear);
      
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
    
    if (academicYear != _currentYear && academicYear.isNotEmpty) {
      _currentYear = academicYear;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchSubjects(academicYear);
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
            fontSize: 22,
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: PremiumTouchButton(
                      enableRipple: false,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
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
                                  Icon(CupertinoIcons.chevron_forward, color: Color(0xFFCBD5E1), size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
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
      cursorColor: const Color(0xFFC62828),
      decoration: InputDecoration(
        hintText: 'Search subjects or codes...',
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 15),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 22.0, right: 8.0),
          child: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        filled: true,
        fillColor: Colors.white,
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
      return {"title": "PPTs", "folder_type": folderType, "icon": Icons.slideshow, "color": const Color(0xFFC62828).withValues(alpha: 0.05), "iconColor": const Color(0xFFC62828), "desc": "Lecture presentations"};
    }
    if (lower == "notes" || lower == "handwritten_notes" || lower == "handwritten notes") {
      return {"title": "Handwritten Notes", "folder_type": folderType, "icon": Icons.edit_note, "color": const Color(0xFFC62828).withValues(alpha: 0.05), "iconColor": const Color(0xFFC62828), "desc": "Notes by students"};
    }
    if (lower == "practicals" || lower == "practical") {
      return {"title": "Practicals", "folder_type": folderType, "icon": Icons.science, "color": const Color(0xFFC62828).withValues(alpha: 0.05), "iconColor": const Color(0xFFC62828), "desc": "Lab manuals & assignments"};
    }
    if (lower == "course_policy" || lower == "course policy" || lower == "policy") {
      return {"title": "Course Policy", "folder_type": folderType, "icon": Icons.policy, "color": const Color(0xFFC62828).withValues(alpha: 0.05), "iconColor": const Color(0xFFC62828), "desc": "Syllabus and grading"};
    }
    if (lower.contains("assignment")) {
      return {"title": folderType, "folder_type": folderType, "icon": Icons.assignment, "color": const Color(0xFFC62828).withValues(alpha: 0.05), "iconColor": const Color(0xFFC62828), "desc": "Course assignments"};
    }
    if (lower.contains("paper") || lower.contains("exam")) {
      return {"title": folderType, "folder_type": folderType, "icon": Icons.text_snippet, "color": const Color(0xFFC62828).withValues(alpha: 0.05), "iconColor": const Color(0xFFC62828), "desc": "Previous year papers"};
    }
    if (lower.contains("book") || lower.contains("reference")) {
      return {"title": folderType, "folder_type": folderType, "icon": Icons.library_books, "color": const Color(0xFFC62828).withValues(alpha: 0.05), "iconColor": const Color(0xFFC62828), "desc": "Reference materials"};
    }

    // Default dynamic style for completely custom categories
    return {
      "title": folderType,
      "folder_type": folderType,
      "icon": Icons.folder,
      "color": const Color(0xFFC62828).withValues(alpha: 0.05),
      "iconColor": const Color(0xFFC62828),
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: PremiumTouchButton(
                        enableRipple: false,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
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
                                    Icon(CupertinoIcons.chevron_forward, color: Color(0xFFCBD5E1), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
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
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Want Special Thanks?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    try {
      final response = await Supabase.instance.client
          .from('materials')
          .select('*')
          .eq('subject_id', widget.subjectId)
          .eq('folder_type', widget.folderType)
          .order('file_date', ascending: false);

      if (mounted) {
        setState(() {
          _materials = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching materials: $e");
      if (mounted) setState(() => _isLoading = false);
    }
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
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              itemCount: _materials.length,
              itemBuilder: (context, index) {
                final mat = _materials[index];
                
                // Determine file type from extension for icon
                final fileName = (mat["file_name"] as String).toLowerCase();
                final isPdf = fileName.endsWith('.pdf');
                
                return PremiumTouchButton(
                  enableRipple: false,
                  child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1),
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
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
                          final urlStr = mat["drive_url"].toString();
                          if (urlStr.isNotEmpty) {
                            if (isPdf) {
                              Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    opaque: true,
                                    pageBuilder: (context, animation, secondaryAnimation) => PdfViewerScreen(
                                      pdfTitle: mat["file_name"],
                                      pdfUrl: urlStr,
                                      pdfType: 'Note',
                                      pdfTimestamp: mat["file_date"] != null ? DateTime.tryParse(mat["file_date"].toString()) : null,
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
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                              ),
                              child: Icon(
                                isPdf ? Icons.picture_as_pdf : Icons.slideshow,
                                color: Theme.of(context).colorScheme.primary,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mat["file_name"],
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, fontFamily: 'Manrope'),
                                    maxLines: 2, overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(_formatDate(mat["file_date"]), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (mat["file_size"] != null) ...[
                                  Icon(Icons.download_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  SizedBox(height: 4),
                                  Text(
                                    "${(mat["file_size"] / 1024 / 1024).toStringAsFixed(1)} MB",
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ));
              },
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
                            color: const Color(0xFFFEE2E2), // Light theme red
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
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
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
                                Text("Disclaimer", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF9A3412))),
                                SizedBox(height: 6),
                                Text(
                                  "These notes do not guarantee full marks. Please refer to official university textbooks for comprehensive preparation.", 
                                  style: TextStyle(fontSize: 14, color: Color(0xFF9A3412), height: 1.5, fontWeight: FontWeight.w500),
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
                                  Text("Cached PDFs", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
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
                                backgroundColor: const Color(0xFFFEF2F2),
                                foregroundColor: const Color(0xFFDC2626),
                                disabledBackgroundColor: const Color(0xFFF1F4F9),
                                disabledForegroundColor: const Color(0xFF94A3B8),
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
          child: Icon(icon, color: const Color(0xFF475569), size: 22),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
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

  const PdfViewerScreen({super.key, required this.pdfTitle, required this.pdfUrl, this.pdfType = 'Material', this.pdfTimestamp});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
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

    return Scaffold(
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
                    color: Theme.of(context).colorScheme.surface,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Opening document...",
                    style: TextStyle(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9), fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  if (_downloadProgress > 0) ...[
                    SizedBox(height: 8),
                    Text(
                      "${(_downloadProgress * 100).toInt()}%",
                      style: TextStyle(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6), fontSize: 14),
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
                  Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 48),
                  SizedBox(height: 16),
                  Text(
                    "Unable to open document",
                    style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _errorMessage ?? "Unknown error",
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
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
              child: PdfViewer.file(
                  _localPdfPath!,
                  controller: _pdfViewController,
                  params: PdfViewerParams(
                    backgroundColor: driveDark,
                    scrollPhysics: const BouncingScrollPhysics(),
                    pageDropShadow: BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 2, offset: Offset(2, 2)),
                    pagePaintCallbacks: [
                      (canvas, pageRect, page) {
                        _textSearcher?.pageTextMatchPaintCallback(canvas, pageRect, page);
                      }
                    ],
                    layoutPages: (pages, params) {
                      final width = pages.fold(0.0, (w, p) => max(w, p.width)) + params.margin * 2;
                      final pageLayouts = <Rect>[];
                      
                      // Only add the top offset for multi-page PDFs to prevent 1-page PDFs from being pushed to the bottom
                      final bool isSinglePage = pages.length == 1;
                      var y = params.margin + (isSinglePage ? 0.0 : (64.0 + topPadding)); 
                      
                      for (final page in pages) {
                        pageLayouts.add(
                          Rect.fromLTWH((width - page.width) / 2, y, page.width, page.height),
                        );
                        y += page.height + params.margin;
                      }
                      return PdfPageLayout(pageLayouts: pageLayouts, documentSize: Size(width, y));
                    },
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
                                    color: Theme.of(context).colorScheme.surface,
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
                                color: Theme.of(context).colorScheme.onSurface,
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
                iconTheme: IconThemeData(color: Theme.of(context).colorScheme.surface),
                titleSpacing: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.surface, size: 24),
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
                      style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 16),
                      autofocus: true,
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: 'Search in document...',
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6), fontSize: 16),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface, size: 20),
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
                      style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 18, fontWeight: FontWeight.w400),
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
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                                ),
                                IconButton(
                                  icon: Icon(Icons.keyboard_arrow_up, color: Theme.of(context).colorScheme.surface),
                                  onPressed: _textSearcher!.hasMatches ? () async {
                                    await _textSearcher!.goToPrevMatch();
                                    _textSearcher!.notifyListeners();
                                  } : null,
                                ),
                                IconButton(
                                  icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.surface),
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
                      IconButton(
                        icon: Icon(Icons.find_in_page_outlined, color: Theme.of(context).colorScheme.surface),
                        onPressed: () {
                          setState(() {
                            _isSearchMode = true;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.share, color: Theme.of(context).colorScheme.surface),
                        onPressed: () {
                          Share.share('Check out this document on Nirma Hub: https://nirma-hub.online');
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
    );
  }
}
