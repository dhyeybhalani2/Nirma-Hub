import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'widgets/skeleton_loaders.dart';
import 'services/rating_service.dart';
import 'help_center_screen.dart';
import 'core/theme/app_theme.dart';

class SgpaCalculatorScreen extends ConsumerStatefulWidget {
  const SgpaCalculatorScreen({super.key});

  @override
  ConsumerState<SgpaCalculatorScreen> createState() => _SgpaCalculatorScreenState();
}

class _SgpaCalculatorScreenState extends ConsumerState<SgpaCalculatorScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allSgpaSubjects = [];
  Map<String, Map<String, dynamic>> _userMarks = {}; 
  
  double _estimatedSgpa = 0.0;
  String? _userYear;
  int _selectedSemester = 1;
  late TabController _tabController;

  // --- Estimated CGPA ---
  /// Admin-defined semester setup rows for this user's academic year.
  List<Map<String, dynamic>> _cgpaConfigs = [];
  /// semester_number -> SGPA the student typed in for a completed semester.
  final Map<int, double> _pastSgpa = {};
  double _estimatedCgpa = 0.0;
  /// How many semesters actually went into [_estimatedCgpa].
  int _cgpaSemesterCount = 0;

  final Map<int, int> gradeToPercent = {
    10: 91, 9: 81, 8: 71, 7: 61, 6: 51, 5: 41, 4: 31, 3: 21, 2: 11, 1: 1
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_selectedSemester != _tabController.index + 1) {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedSemester = _tabController.index + 1;
            _calculateOverallSgpa();
          });
        }
      }
    });
    _fetchSgpaData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSgpaData() async {
    final userProfile = ref.read(authNotifierProvider).value;
    if (userProfile == null) return;
    
    try {
      final userBranch = userProfile.branch;
      final userYear = userProfile.academicYear;
      
      final supabase = Supabase.instance.client;
      
      // 1. Fetch Subjects and Configs for this user's branch/year
      final configsResponse = await supabase
          .from('sgpa_subject_configs')
          .select('id, subject_id, semester, subjects!inner(name, code, branch, academic_year), sgpa_methods!inner(name, components, has_see)');
          
      // Filter locally for now to handle "Common" and specific branch matching
      List<Map<String, dynamic>> validSubjects = [];
      for (var config in configsResponse as List<dynamic>) {
        final subject = config['subjects'];
        if (subject['academic_year'] == userYear && 
           (subject['branch'] == 'Common' || subject['branch'] == userBranch)) {
          validSubjects.add({
            'config_id': config['id'],
            'subject_id': config['subject_id'],
            'semester': config['semester'] ?? 0,
            'name': subject['name'],
            'code': subject['code'],
            'method_name': config['sgpa_methods']['name'],
            'components': config['sgpa_methods']['components'],
            'has_see': config['sgpa_methods']['has_see'],
          });
        }
      }

      // 2. Fetch User's saved marks for these subjects
      Map<String, Map<String, dynamic>> marksMap = {};
      
      try {
        final marksResponse = await supabase
            .from('sgpa_user_marks')
            .select('subject_id, target_grade, marks_data, calculation_count')
            .eq('user_id', userProfile.id);
            
        for (var m in marksResponse as List<dynamic>) {
          // Safe conversion of the Map
          final marksData = m['marks_data'];
          final cleanMarksData = marksData != null 
              ? Map<String, dynamic>.from(marksData as Map)
              : <String, dynamic>{};

          marksMap[m['subject_id']] = {
            'target_grade': m['target_grade'],
            'marks_data': cleanMarksData,
            'calculation_count': m['calculation_count'] ?? 0,
          };
        }
      } catch (marksError) {
        debugPrint("Could not fetch user marks (might be missing calculation_count column): $marksError");
        // We continue without marks so subjects still show up!
      }
      
      // 3. Fetch the admin's CGPA semester setup for this academic year
      List<Map<String, dynamic>> cgpaConfigs = [];
      Map<int, double> pastSgpaMap = {};

      try {
        final cgpaResponse = await supabase
            .from('cgpa_configs')
            .select('academic_year, applies_to_semester, current_semester, past_semesters, is_enabled')
            .eq('academic_year', userYear)
            .eq('is_enabled', true);

        for (var c in cgpaResponse as List<dynamic>) {
          cgpaConfigs.add({
            'academic_year': c['academic_year'],
            'applies_to_semester': (c['applies_to_semester'] as num?)?.toInt() ?? 0,
            'current_semester': (c['current_semester'] as num?)?.toInt() ?? 1,
            'past_semesters': c['past_semesters'] is List
                ? List<dynamic>.from(c['past_semesters'] as List)
                : <dynamic>[],
          });
        }

        // 4. Fetch the SGPAs this user already saved for past semesters
        final pastResponse = await supabase
            .from('user_past_sgpa')
            .select('semester_number, sgpa')
            .eq('user_id', userProfile.id);

        for (var row in pastResponse as List<dynamic>) {
          final semNo = (row['semester_number'] as num?)?.toInt();
          final value = (row['sgpa'] as num?)?.toDouble();
          if (semNo != null && value != null) pastSgpaMap[semNo] = value;
        }
      } catch (cgpaError) {
        debugPrint("Could not fetch CGPA setup: $cgpaError");
        // Not fatal - the screen still works as a plain SGPA calculator.
      }

      // Initialize missing marks map entries
      for (var sub in validSubjects) {
        if (!marksMap.containsKey(sub['subject_id'])) {
          marksMap[sub['subject_id']] = {
            'marks_data': <String, dynamic>{},
            'target_grade': 0,
            'required_see': null
          };
        }
      }

      setState(() {
        _userYear = userYear;
        _allSgpaSubjects = validSubjects;
        _userMarks = marksMap;
        _cgpaConfigs = cgpaConfigs;
        _pastSgpa
          ..clear()
          ..addAll(pastSgpaMap);
        _isLoading = false;
        _calculateOverallSgpa();
      });
      
    } catch (e) {
      debugPrint("Error fetching SGPA data: $e");
      setState(() { _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _visibleSubjects {
    if (_userYear != '1st') return _allSgpaSubjects;
    return _allSgpaSubjects.where((s) => s['semester'] == 0 || s['semester'] == _selectedSemester).toList();
  }

  /// The semester setup that applies right now. 1st year has one row per
  /// SGPA tab; every other year uses the `applies_to_semester = 0` row.
  Map<String, dynamic>? get _activeCgpaConfig {
    if (_cgpaConfigs.isEmpty) return null;

    if (_userYear == '1st') {
      for (final c in _cgpaConfigs) {
        if (c['applies_to_semester'] == _selectedSemester) return c;
      }
    }
    for (final c in _cgpaConfigs) {
      if (c['applies_to_semester'] == 0) return c;
    }
    return _cgpaConfigs.first;
  }

  void _calculateOverallSgpa() {
    final visible = _visibleSubjects;
    int totalGrade = 0;
    int subjectsWithGrade = 0;

    for (var sub in visible) {
      final marks = _userMarks[sub['subject_id']];
      if (marks != null && marks['target_grade'] != null && (marks['target_grade'] as num) > 0) {
        totalGrade += (marks['target_grade'] as num).toInt();
        subjectsWithGrade++;
      }
    }

    setState(() {
      _estimatedSgpa = subjectsWithGrade > 0 ? (totalGrade / subjectsWithGrade) : 0.0;
      _recalculateCgpa();
    });
  }

  /// CGPA = mean of every past-semester SGPA the student entered plus the live
  /// estimated SGPA of the current semester. Semesters left blank are excluded
  /// from both the sum and the divisor.
  void _recalculateCgpa() {
    final config = _activeCgpaConfig;
    if (config == null) {
      _estimatedCgpa = 0.0;
      _cgpaSemesterCount = 0;
      return;
    }

    double total = 0.0;
    int count = 0;

    for (final entry in (config['past_semesters'] as List<dynamic>)) {
      if (entry is! Map) continue;
      final semNo = (entry['number'] as num?)?.toInt();
      if (semNo == null) continue;
      final value = _pastSgpa[semNo];
      if (value != null && value > 0) {
        total += value;
        count++;
      }
    }

    if (_estimatedSgpa > 0) {
      total += _estimatedSgpa;
      count++;
    }

    _estimatedCgpa = count > 0 ? total / count : 0.0;
    _cgpaSemesterCount = count;
  }

  /// Stores one past-semester SGPA. Pass null to clear it.
  Future<void> _savePastSgpa(int semesterNumber, double? value) async {
    if (mounted) {
      setState(() {
        if (value == null) {
          _pastSgpa.remove(semesterNumber);
        } else {
          _pastSgpa[semesterNumber] = value;
        }
        _recalculateCgpa();
      });
    }

    final userProfile = ref.read(authNotifierProvider).value;
    if (userProfile == null) return;

    final supabase = Supabase.instance.client;
    try {
      if (value == null) {
        await supabase
            .from('user_past_sgpa')
            .delete()
            .eq('user_id', userProfile.id)
            .eq('semester_number', semesterNumber);
      } else {
        await supabase.from('user_past_sgpa').upsert({
          'user_id': userProfile.id,
          'semester_number': semesterNumber,
          'sgpa': value,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id, semester_number');
      }
    } catch (e) {
      debugPrint("Could not save past SGPA for semester $semesterNumber: $e");
    }
  }

  Future<void> _calculateSubject(String subjectId, Map<String, dynamic> methodData, Map<String, num> inputs, int targetGrade) async {
    HapticFeedback.lightImpact();
    
    double internal = 0;
    List<dynamic> components = methodData['components'];
    
    for (var comp in components) {
      final String compName = comp['name'];
      final num maxMarks = comp['max_marks'];
      final num weight = comp['weight'];
      
      final num userVal = inputs[compName] ?? 0;
      internal += (userVal / maxMarks) * weight;
    }
    
    int reqPercent = gradeToPercent[targetGrade] ?? 0;
    double requiredSee = (reqPercent - internal) * 2;
    
    if (requiredSee < 0) requiredSee = 0;
    
    bool hasSee = methodData['has_see'] == true;
    if (!hasSee) {
      // Auto-calculate grade from internal marks
      if (internal >= 91) targetGrade = 10;
      else if (internal >= 81) targetGrade = 9;
      else if (internal >= 71) targetGrade = 8;
      else if (internal >= 61) targetGrade = 7;
      else if (internal >= 51) targetGrade = 6;
      else if (internal >= 41) targetGrade = 5;
      else if (internal >= 31) targetGrade = 4;
      else if (internal >= 21) targetGrade = 3;
      else if (internal >= 11) targetGrade = 2;
      else if (internal >= 1) targetGrade = 1;
      else targetGrade = 0;
    }
    
    int currentCount = (_userMarks[subjectId]?['calculation_count'] as num?)?.toInt() ?? 0;
    int newCount = currentCount + 1;
    
    if (mounted) {
      setState(() {
        if (!_userMarks.containsKey(subjectId)) {
          _userMarks[subjectId] = {};
        }
        _userMarks[subjectId]!['marks_data'] = inputs;
        _userMarks[subjectId]!['target_grade'] = targetGrade;
        _userMarks[subjectId]!['required_see'] = hasSee ? requiredSee : -1.0; 
        _userMarks[subjectId]!['total_internal'] = internal;
        _userMarks[subjectId]!['calculation_count'] = newCount;
        _calculateOverallSgpa();
      });
    }
    
    // Save to Supabase
    final userProfile = ref.read(authNotifierProvider).value;
    if (userProfile != null) {
      final supabase = Supabase.instance.client;
      await supabase.from('sgpa_user_marks').upsert({
        'user_id': userProfile.id,
        'subject_id': subjectId,
        'marks_data': inputs,
        'target_grade': targetGrade,
        'calculation_count': newCount,
        'updated_at': DateTime.now().toIso8601String()
      }, onConflict: 'user_id, subject_id');
    }

    // Trigger Google Play In-App Review check (at 15 clicks, then every 30 clicks: 45, 75, 105...)
    RatingService().onSgpaCalculationDone();
  }

  void _showDisclaimerDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with title and close icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.c.accentFill.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(CupertinoIcons.info_circle_fill, color: context.c.accent, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "About SGPA Calculator",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Disclaimer Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text("🎓", style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Educational Purpose Only",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "This tool is created by a student for educational purposes only. It is not an official Nirma University system. Calculations are approximate and may differ from official results. Always verify with university guidelines.",
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Supporting Free App with Ads Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text("☕", style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Keeping Nirma Hub Free & Alive",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: context.c.pick(const Color(0xFFD97706), const Color(0xFFFBBF24)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Minimal sponsor ads help cover server hosting, database costs, and keep free tools running for every student. We truly appreciate your support!",
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Have a Query -> Redirect to Help Center
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const HelpCenterScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.question_circle_fill, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Have a query or feedback?",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            "Get in touch with support or request new subjects",
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(CupertinoIcons.chevron_right, color: Theme.of(context).colorScheme.primary, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
        title: Text(
          'SGPA Calculator',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
            fontFamily: 'Manrope',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showDisclaimerDialog(context),
                  child: SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(
                      CupertinoIcons.info_circle,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading 
        ? const SgpaSkeleton()
        : _allSgpaSubjects.isEmpty 
          ? const Center(child: Text("No SGPA methods configured for your branch/year yet."))
          : GestureDetector(
              onHorizontalDragEnd: (details) {
                if (_userYear != '1st') return;
                if (details.primaryVelocity! < -300) {
                  // Swipe left -> Sem 2
                  if (_tabController.index == 0) {
                    _tabController.animateTo(1);
                  }
                } else if (details.primaryVelocity! > 300) {
                  // Swipe right -> Sem 1
                  if (_tabController.index == 1) {
                    _tabController.animateTo(0);
                  }
                }
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                physics: const BouncingScrollPhysics(),
                children: [
                  if (_userYear == '1st') ...[
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: context.c.border, width: 1)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        onTap: (index) {
                          _tabController.animateTo(index);
                        },
                        isScrollable: false,
                        splashFactory: NoSplash.splashFactory,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelColor: context.c.accent,
                        unselectedLabelColor: context.c.textMuted,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'Manrope'),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Manrope'),
                        indicatorColor: context.c.accent,
                        indicatorWeight: 3,
                        dividerColor: Colors.transparent,
                        overlayColor: WidgetStateProperty.all(Colors.transparent),
                        tabs: const [
                          Tab(text: 'SEMESTER 1'),
                          Tab(text: 'SEMESTER 2'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
                // Header Card Dashboard
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.c.hero,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.c.heroBorder),
                    boxShadow: [
                      BoxShadow(
                        color: context.c.isDark
                            ? Colors.black.withValues(alpha: 0.5)
                            : const Color(0xFFC62828).withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Estimated SGPA",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Manrope'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Based on targets",
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 80,
                        width: 80,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: _estimatedSgpa > 0 ? _estimatedSgpa / 10.0 : 0.0,
                              strokeWidth: 8,
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _estimatedSgpa == 0.0 
                                  ? Colors.transparent
                                  : _estimatedSgpa >= 8.5 
                                    ? const Color(0xFF10B981) 
                                    : _estimatedSgpa >= 6.5 
                                      ? const Color(0xFFF59E0B) 
                                      : const Color(0xFFEF4444) 
                              ),
                            ),
                            Center(
                              child: Text(
                                _estimatedSgpa.toStringAsFixed(2),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Manrope',
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Estimated CGPA (only when the admin configured past semesters)
                if (_activeCgpaConfig != null &&
                    (_activeCgpaConfig!['past_semesters'] as List).isNotEmpty) ...[
                  _CgpaCard(
                    key: ValueKey(
                      'cgpa-${_activeCgpaConfig!['academic_year']}-${_activeCgpaConfig!['applies_to_semester']}',
                    ),
                    config: _activeCgpaConfig!,
                    pastSgpa: _pastSgpa,
                    estimatedSgpa: _estimatedSgpa,
                    estimatedCgpa: _estimatedCgpa,
                    semesterCount: _cgpaSemesterCount,
                    onChanged: _savePastSgpa,
                  ),
                  const SizedBox(height: 24),
                ],

                // Subject Cards
                ..._visibleSubjects.map((sub) {
                  return _SubjectCalcCard(
                    key: ValueKey(sub['subject_id']),
                    subjectData: sub,
                    initialMarks: _userMarks[sub['subject_id']]?['marks_data'] ?? <String, dynamic>{},
                    initialTargetGrade: _userMarks[sub['subject_id']]?['target_grade'] ?? 0,
                    requiredSee: _userMarks[sub['subject_id']]?['required_see'],
                    totalInternal: _userMarks[sub['subject_id']]?['total_internal'],
                    onCalculate: (inputs, targetGrade) {
                      _calculateSubject(sub['subject_id'], sub, inputs, targetGrade);
                    },
                  );
                }),
                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }
}

class _SubjectCalcCard extends StatefulWidget {
  final Map<String, dynamic> subjectData;
  final Map<String, dynamic> initialMarks;
  final int initialTargetGrade;
  final double? requiredSee;
  final double? totalInternal;
  final Function(Map<String, num>, int) onCalculate;

  const _SubjectCalcCard({
    super.key,
    required this.subjectData,
    required this.initialMarks,
    required this.initialTargetGrade,
    this.requiredSee,
    this.totalInternal,
    required this.onCalculate,
  });

  @override
  State<_SubjectCalcCard> createState() => _SubjectCalcCardState();
}

class _SubjectCalcCardState extends State<_SubjectCalcCard> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final TextEditingController _targetController = TextEditingController();
  final FocusNode _targetFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _targetController.text = widget.initialTargetGrade > 0 ? widget.initialTargetGrade.toString() : '';
    _targetFocusNode.addListener(() => setState(() {}));
    
    final components = widget.subjectData['components'] as List<dynamic>;
    for (var comp in components) {
      final name = comp['name'] as String;
      final initialVal = widget.initialMarks[name];
      _controllers[name] = TextEditingController(
        text: initialVal != null ? (initialVal is num ? initialVal.toInt().toString() : initialVal.toString()) : '',
      );
      _focusNodes[name] = FocusNode()..addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _targetController.dispose();
    _targetFocusNode.dispose();
    for (var c in _controllers.values) {
      c.dispose();
    }
    for (var f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _handleCalculate() {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus(); // Dismiss the keyboard
    
    Map<String, num> inputs = {};
    final components = widget.subjectData['components'] as List<dynamic>;
    
    for (var comp in components) {
      final name = comp['name'] as String;
      final text = _controllers[name]?.text ?? '0';
      inputs[name] = int.tryParse(text) ?? 0;
    }
    
    int targetGrade = int.tryParse(_targetController.text) ?? 0;
    widget.onCalculate(inputs, targetGrade);
  }

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
    return context.c.tint(colors[hash % colors.length]);
  }

  Widget _buildResultBox() {
    if (widget.requiredSee == null) return const SizedBox.shrink();
    
    Widget resultWidget;
    if (widget.requiredSee == -1.0) {
      resultWidget = Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.c.purpleSoft, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.c.purpleBorder, width: 1.5),
          boxShadow: [
             BoxShadow(color: context.c.purpleBorder.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(
              "Total: ${widget.totalInternal?.toStringAsFixed(1) ?? '0.0'} / 100",
              textAlign: TextAlign.center,
              style: TextStyle(color: context.c.purple, fontWeight: FontWeight.w800, fontSize: 16, fontFamily: 'Manrope'),
            ),
            const SizedBox(height: 4),
            Text(
              "Grade: ${widget.initialTargetGrade}",
              textAlign: TextAlign.center,
              style: TextStyle(color: context.c.purple, fontWeight: FontWeight.w800, fontSize: 16, fontFamily: 'Manrope'),
            ),
          ],
        ),
      );
    } else {
      bool isAchieved = widget.requiredSee! <= 0;
      bool isImpossible = widget.requiredSee! > 100;
      
      int requiredMarks = widget.requiredSee!.ceil();
      int upperRange = requiredMarks + 19;
      if (upperRange > 100) upperRange = 100;

      Color boxColor = isAchieved ? context.c.success : (isImpossible ? context.c.danger : context.c.warning);
      Color bgColor = isAchieved ? context.c.successSoft : (isImpossible ? context.c.dangerSoft : context.c.warningSoft);
      Color borderColor = isAchieved ? context.c.successBorder : (isImpossible ? context.c.dangerBorder : context.c.warningBorder);
      
      Widget messageWidget;
      if (isAchieved) {
        messageWidget = Text(
          "Goal Achieved! (0 marks needed)",
          textAlign: TextAlign.center,
          style: TextStyle(color: boxColor, fontWeight: FontWeight.w800, fontSize: 15, fontFamily: 'Manrope'),
        );
      } else if (isImpossible) {
        messageWidget = Text(
          "Impossible! Need $requiredMarks/100",
          textAlign: TextAlign.center,
          style: TextStyle(color: boxColor, fontWeight: FontWeight.w800, fontSize: 15, fontFamily: 'Manrope'),
        );
      } else {
        messageWidget = RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(color: context.c.warningText, fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Manrope'),
            children: [
              const TextSpan(text: "Between "),
              TextSpan(text: "$requiredMarks", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const TextSpan(text: " to "),
              TextSpan(text: "$upperRange", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const TextSpan(text: " marks"),
            ],
          ),
        );
      }

      resultWidget = Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(color: boxColor.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isAchieved 
                ? Icon(CupertinoIcons.checkmark_seal_fill, color: boxColor, size: 20)
                : Text(isImpossible ? "⚠️" : "🎯", style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Flexible(
              child: messageWidget,
            ),
          ],
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.requiredSee),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, val, child) {
        return Transform.scale(
          scale: val,
          child: Opacity(
            opacity: val.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: resultWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final components = widget.subjectData['components'] as List<dynamic>;
    bool hasSee = widget.subjectData['has_see'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: context.c.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _getColorForSubject(widget.subjectData['name']),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getIconColorForSubject(widget.subjectData['name']).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Icon(_getIconForSubject(widget.subjectData['name']), color: _getIconColorForSubject(widget.subjectData['name']), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.subjectData['name'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Divider(color: Theme.of(context).colorScheme.outlineVariant, thickness: 1.0),
              ),
          
          ...components.map((comp) {
            final name = comp['name'] as String;
            final maxMarks = comp['max_marks'] as num;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  Container(
                    width: 110,
                    height: 46,
                    decoration: BoxDecoration(
                      color: context.c.fill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _focusNodes[name]?.hasFocus == true 
                            ? context.c.accent 
                            : context.c.border, 
                        width: _focusNodes[name]?.hasFocus == true ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            focusNode: _focusNodes[name],
                            cursorColor: context.c.accent,
                            controller: _controllers[name],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            textAlignVertical: TextAlignVertical.center,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.c.text),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (val) {
                              int parsed = int.tryParse(val) ?? 0;
                              if (parsed > maxMarks.toInt()) {
                                _controllers[name]!.text = maxMarks.toInt().toString();
                                _controllers[name]!.selection = TextSelection.fromPosition(
                                  TextPosition(offset: _controllers[name]!.text.length),
                                );
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Text("/${maxMarks.toInt()}", style: TextStyle(color: context.c.textFaint, fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          
          if (hasSee) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(color: Theme.of(context).colorScheme.outlineVariant, thickness: 1.0),
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Target Grade",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, fontFamily: 'Manrope'),
                ),
                Container(
                  width: 110,
                  height: 46,
                  decoration: BoxDecoration(
                    color: context.c.fill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _targetFocusNode.hasFocus 
                          ? context.c.accent 
                          : context.c.borderStrong, 
                      width: _targetFocusNode.hasFocus ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          focusNode: _targetFocusNode,
                          cursorColor: context.c.accent,
                          controller: _targetController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.c.text),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          onChanged: (val) {
                            int parsed = int.tryParse(val) ?? 0;
                            if (parsed > 10) {
                              _targetController.text = '10';
                              _targetController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _targetController.text.length),
                              );
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 12.0),
                        child: Text("/10", style: TextStyle(color: context.c.textFaint, fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(color: Theme.of(context).colorScheme.outlineVariant, thickness: 1.0),
            ),
            Text(
              "${widget.subjectData['name']} has no SEE exam. Grade is internal.",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _handleCalculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.c.hero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text("Calculate Required", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Manrope')),
            ),
          ),
          _buildResultBox(),
        ],
      ),
    ),
    );
  }
}


/// Lets the student type the SGPA of each completed semester (the list of
/// semesters comes from `cgpa_configs` in Supabase) and shows the resulting
/// estimated CGPA together with the live SGPA of the running semester.
class _CgpaCard extends StatefulWidget {
  final Map<String, dynamic> config;
  final Map<int, double> pastSgpa;
  final double estimatedSgpa;
  final double estimatedCgpa;
  final int semesterCount;
  final Future<void> Function(int semesterNumber, double? sgpa) onChanged;

  const _CgpaCard({
    super.key,
    required this.config,
    required this.pastSgpa,
    required this.estimatedSgpa,
    required this.estimatedCgpa,
    required this.semesterCount,
    required this.onChanged,
  });

  @override
  State<_CgpaCard> createState() => _CgpaCardState();
}

class _CgpaCardState extends State<_CgpaCard> {
  Color get _accent => context.c.pick(const Color(0xFF4F46E5), const Color(0xFFA5B4FC));

  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  final Map<int, Timer> _debouncers = {};

  List<Map<String, dynamic>> get _pastSemesters {
    final raw = widget.config['past_semesters'] as List<dynamic>;
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final number = (e['number'] as num?)?.toInt();
      if (number == null) continue;
      out.add({
        'number': number,
        'label': (e['label'] as String?)?.trim().isNotEmpty == true
            ? e['label'] as String
            : 'Semester $number',
      });
    }
    out.sort((a, b) => (a['number'] as int).compareTo(b['number'] as int));
    return out;
  }

  @override
  void initState() {
    super.initState();
    for (final sem in _pastSemesters) {
      final number = sem['number'] as int;
      final saved = widget.pastSgpa[number];
      _controllers[number] = TextEditingController(
        text: saved != null ? _trim(saved) : '',
      );
      _focusNodes[number] = FocusNode()..addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final t in _debouncers.values) {
      t.cancel();
    }
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  /// 8.50 -> "8.5", 9.00 -> "9"
  static String _trim(double value) {
    final text = value.toStringAsFixed(2);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _onFieldChanged(int semesterNumber, String raw) {
    final controller = _controllers[semesterNumber]!;

    // Clamp to the 0-10 scale while typing.
    final parsed = double.tryParse(raw);
    if (parsed != null && parsed > 10) {
      controller.text = '10';
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
      raw = '10';
    }

    _debouncers[semesterNumber]?.cancel();
    _debouncers[semesterNumber] = Timer(const Duration(milliseconds: 600), () {
      final value = double.tryParse(controller.text.trim());
      widget.onChanged(
        semesterNumber,
        (value == null || value <= 0) ? null : value,
      );
    });
  }

  Color _gradeColor(double value) {
    if (value >= 8.5) return context.c.success;
    if (value >= 6.5) return context.c.warning;
    return context.c.danger;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSemester = (widget.config['current_semester'] as num?)?.toInt() ?? 0;
    final cgpa = widget.estimatedCgpa;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: context.c.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Header ----
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accent.withValues(alpha: 0.15)),
                  ),
                  child: Icon(CupertinoIcons.chart_bar_alt_fill, color: _accent, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Estimated CGPA",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.semesterCount > 0
                            ? "Across ${widget.semesterCount} semester${widget.semesterCount == 1 ? '' : 's'}"
                            : "Enter your past semester SGPA",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  cgpa > 0 ? cgpa.toStringAsFixed(2) : "--",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Manrope',
                    letterSpacing: -1,
                    color: cgpa > 0 ? _gradeColor(cgpa) : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Divider(color: theme.colorScheme.outlineVariant, thickness: 1.0),
            ),

            // ---- Past semesters the student fills in ----
            ..._pastSemesters.map((sem) {
              final number = sem['number'] as int;
              final hasFocus = _focusNodes[number]?.hasFocus == true;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "${sem['label']} SGPA",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 110,
                      height: 46,
                      decoration: BoxDecoration(
                        color: context.c.fill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasFocus ? _accent : context.c.border,
                          width: hasFocus ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              focusNode: _focusNodes[number],
                              controller: _controllers[number],
                              cursorColor: _accent,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.right,
                              textAlignVertical: TextAlignVertical.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: context.c.text,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  color: context.c.borderStrong,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}\.?\d{0,2}')),
                              ],
                              onChanged: (val) => _onFieldChanged(number, val),
                              onEditingComplete: () {
                                _debouncers[number]?.cancel();
                                final value = double.tryParse(_controllers[number]!.text.trim());
                                widget.onChanged(
                                  number,
                                  (value == null || value <= 0) ? null : value,
                                );
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 12.0),
                            child: Text(
                              "/10",
                              style: TextStyle(
                                color: context.c.textFaint,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            // ---- The running semester, taken from the calculator above ----
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      currentSemester > 0
                          ? "Semester $currentSemester SGPA (estimated)"
                          : "Current semester SGPA (estimated)",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 110,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accent.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      widget.estimatedSgpa > 0
                          ? "${widget.estimatedSgpa.toStringAsFixed(2)} /10"
                          : "-- /10",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: _accent,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                widget.semesterCount > 0
                    ? "CGPA is the average of the ${widget.semesterCount} semester${widget.semesterCount == 1 ? '' : 's'} counted above. Semesters left blank are skipped."
                    : "Fill in your past semester SGPA and set targets above to see your estimated CGPA.",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
