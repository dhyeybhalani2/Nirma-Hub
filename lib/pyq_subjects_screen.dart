import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'search_helper.dart';
import 'widgets/premium_touch_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'pyq_list_screen.dart';
import 'widgets/skeleton_loaders.dart';

class PyqSubjectsScreen extends ConsumerStatefulWidget {
  const PyqSubjectsScreen({super.key});

  @override
  ConsumerState<PyqSubjectsScreen> createState() => _PyqSubjectsScreenState();
}

class _PyqSubjectsScreenState extends ConsumerState<PyqSubjectsScreen> {
  String _searchQuery = "";
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;
  String _currentYear = "";
  String _currentBranch = "";

  IconData _getIconForSubject(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math') || lower.contains('stat')) return Icons.calculate;
    if (lower.contains('comput') || lower.contains('ai') || lower.contains('web')) return Icons.computer;
    if (lower.contains('electric')) return Icons.electrical_services;
    if (lower.contains('eng') || lower.contains('comm')) return Icons.book;
    if (lower.contains('phys')) return Icons.science;
    if (lower.contains('env')) return Icons.eco;
    if (lower.contains('data') || lower.contains('algo')) return Icons.account_tree;
    if (lower.contains('network')) return Icons.router;
    return Icons.menu_book;
  }

  Color _getColorForSubject(String name) {
    return const Color(0xFFE11D48).withValues(alpha: 0.05);
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
          "pyq_special_thanks": s["pyq_special_thanks"],
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
      final nameLower = s["name"].toLowerCase();
      final codeLower = s["code"].toLowerCase();
      final queryLower = _searchQuery.toLowerCase().trim();
      final queryClean = queryLower.replaceAll(RegExp(r'[^a-z0-9]'), '');
      
      final acronym = generateShortForm(s["name"] as String);
      
      return nameLower.contains(queryLower) || 
             codeLower.contains(queryLower) || 
             acronym.contains(queryClean);
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        ),
        title: Text(
          'PYQs',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Theme.of(context).colorScheme.onSurface,
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
                      Icon(CupertinoIcons.doc_on_clipboard, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          "There are no PYQs Uploaded for current year",
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
                                    builder: (context) => PyqListScreen(
                                      subjectId: subject["id"],
                                      subjectName: subject["name"],
                                      subjectCode: subject["code"],
                                      specialThanks: subject["pyq_special_thanks"] ?? 'Seniors',
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
                                      color: subject["color"],
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
