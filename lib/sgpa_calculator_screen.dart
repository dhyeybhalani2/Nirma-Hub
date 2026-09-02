import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'widgets/skeleton_loaders.dart';
import 'services/rating_service.dart';
import 'services/ad_service.dart';
import 'widgets/ad_banner_widget.dart';
import 'widgets/ad_native_widget.dart';
import 'help_center_screen.dart';

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

  final Map<int, int> gradeToPercent = {
    10: 91, 9: 81, 8: 71, 7: 61, 6: 51, 5: 41, 4: 31, 3: 21, 2: 11, 1: 1
  };

  @override
  void initState() {
    super.initState();
    AdService().preloadRewardedAd();
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

  void _calculateOverallSgpa() {
    final visible = _visibleSubjects;
    if (visible.isEmpty) return;
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
    });
  }

  Future<void> _calculateSubject(String subjectId, Map<String, dynamic> methodData, Map<String, num> inputs, int targetGrade) async {
    HapticFeedback.lightImpact();
    
    // Process calculation click with strict Anti-Bypass Protection (shows ad FIRST if 10th click)
    await AdService().processSgpaCalculation(
      context: context,
      onProceed: () async {
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
      },
    );
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
                    color: const Color(0xFFC62828).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(CupertinoIcons.info_circle_fill, color: Color(0xFFC62828), size: 20),
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
                        const Text(
                          "Keeping Nirma Hub Free & Alive",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD97706),
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
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: const AdBannerWidget(placementKey: 'sgpa_calculator'),
        ),
      ),
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
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        onTap: (index) {
                          _tabController.animateTo(index);
                        },
                        isScrollable: false,
                        splashFactory: NoSplash.splashFactory,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelColor: const Color(0xFFC62828),
                        unselectedLabelColor: const Color(0xFF64748B),
                        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'Manrope'),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Manrope'),
                        indicatorColor: const Color(0xFFC62828),
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
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF1E293B)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC62828).withValues(alpha: 0.15),
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
                
                // Subject Cards
                ..._visibleSubjects.asMap().entries.map((entry) {
                  final index = entry.key;
                  final sub = entry.value;
                  final card = _SubjectCalcCard(
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

                  // Show Native Ad dynamically based on remote/cached interval
                  final int nativeInterval = AdService().sgpaNativeInterval;
                  if (nativeInterval > 0 &&
                      (index + 1) % nativeInterval == 0 &&
                      index != _visibleSubjects.length - 1) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        card,
                        const AdNativeCard(
                          placementKey: 'sgpa_in_between_subjects',
                          isMediumTemplate: false,
                          margin: EdgeInsets.only(bottom: 16),
                        ),
                      ],
                    );
                  }
                  return card;
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
      _controllers[name] = TextEditingController(text: initialVal != null ? initialVal.toString() : '');
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
      inputs[name] = num.tryParse(text) ?? 0;
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
    return colors[hash % colors.length];
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
          color: const Color(0xFFF3E8FF), 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD8B4FE), width: 1.5),
          boxShadow: [
             BoxShadow(color: const Color(0xFFD8B4FE).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(
              "Total: ${widget.totalInternal?.toStringAsFixed(1) ?? '0.0'} / 100",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B21A8), fontWeight: FontWeight.w800, fontSize: 16, fontFamily: 'Manrope'),
            ),
            const SizedBox(height: 4),
            Text(
              "Grade: ${widget.initialTargetGrade}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B21A8), fontWeight: FontWeight.w800, fontSize: 16, fontFamily: 'Manrope'),
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

      Color boxColor = isAchieved ? const Color(0xFF10B981) : (isImpossible ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));
      Color bgColor = isAchieved ? const Color(0xFFD1FAE5) : (isImpossible ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7));
      Color borderColor = isAchieved ? const Color(0xFFA7F3D0) : (isImpossible ? const Color(0xFFFECACA) : const Color(0xFFFDE68A));
      
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
            style: const TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Manrope'),
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
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
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _focusNodes[name]?.hasFocus == true 
                            ? const Color(0xFFC62828) 
                            : const Color(0xFFE2E8F0), 
                        width: _focusNodes[name]?.hasFocus == true ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            focusNode: _focusNodes[name],
                            cursorColor: const Color(0xFFC62828),
                            controller: _controllers[name],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                            ],
                            onChanged: (val) {
                              num parsed = num.tryParse(val) ?? 0;
                              if (parsed > maxMarks) {
                                _controllers[name]!.text = maxMarks.toString();
                                _controllers[name]!.selection = TextSelection.fromPosition(
                                  TextPosition(offset: _controllers[name]!.text.length),
                                );
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Text("/$maxMarks", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w700)),
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
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _targetFocusNode.hasFocus 
                          ? const Color(0xFFC62828) 
                          : const Color(0xFFCBD5E1), 
                      width: _targetFocusNode.hasFocus ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          focusNode: _targetFocusNode,
                          cursorColor: const Color(0xFFC62828),
                          controller: _targetController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
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
                      const Padding(
                        padding: EdgeInsets.only(right: 12.0),
                        child: Text("/10", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w700)),
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
                backgroundColor: const Color(0xFF0F172A),
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
