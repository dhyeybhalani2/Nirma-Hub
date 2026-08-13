import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai/features/auth/presentation/providers/auth_provider.dart';
import 'package:ai/features/sgpa/presentation/providers/sgpa_provider.dart';
import 'package:ai/features/sgpa/data/sgpa_service.dart';


class SGPACalculatorPage extends ConsumerStatefulWidget {
  const SGPACalculatorPage({super.key});

  @override
  ConsumerState<SGPACalculatorPage> createState() => _SGPACalculatorPageState();
}

class _SGPACalculatorPageState extends ConsumerState<SGPACalculatorPage> {
  String selectedSemester = "";
  int currentBottomNavIndex = 0; // Home is active
  Map<String, List<SubjectData>> _localStateSubjects = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sgpaProvider.notifier).refresh();
    });
  }

  void _initSubjects(String semester, List<dynamic> sgpaSubjects, Map<String, dynamic> userMarks) {
    if (!_localStateSubjects.containsKey(semester)) {
      final semMarks = userMarks[semester] is Map ? userMarks[semester] as Map : {};

      _localStateSubjects[semester] = sgpaSubjects.map((s) {
        final subjMarks = semMarks[s.subject] is Map ? semMarks[s.subject] as Map : {};

        final subjectData = SubjectData(
          title: s.subject,
          rows: s.components.map((c) {
            String savedValue = subjMarks[c.label]?.toString() ?? "";
            final row = SubjectRow(label: c.label, maxMarks: c.maxMarks);
            if (savedValue.isNotEmpty) {
              row.controller.text = savedValue;
            }
            return row;
          }).toList().cast<SubjectRow>()
        );
        
        if (subjMarks.containsKey('Target Grade')) {
          subjectData.targetGradeController.text = subjMarks['Target Grade'].toString();
        }
        
        return subjectData;
      }).toList();
    }
  }

  String _calculateEstimatedSGPA(List<SubjectData> subjects) {
    if (subjects.isEmpty) return '0.00';
    
    double totalGrade = 0;
    for (var subject in subjects) {
      double? grade = double.tryParse(subject.targetGradeController.text);
      if (grade != null && grade >= 0 && grade <= 10) {
        totalGrade += grade;
      }
    }
    return (totalGrade / subjects.length).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProfile = ref.watch(authNotifierProvider).value;
    final sgpaData = ref.watch(sgpaProvider);
    final userMarksAsync = ref.watch(userMarksProvider);
    final userMarks = userMarksAsync.value;

    if (userProfile == null || sgpaData == null || userMarks == null) {
      return Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }

    final String cleanYear = userProfile.academicYear.toLowerCase().contains("1st") ? "1st Year" : "2nd Year";
    final List<String> availableSemesters = cleanYear == "1st Year" ? ["1", "2"] : ["3", "4"];
    
    if (selectedSemester.isEmpty || !availableSemesters.contains(selectedSemester)) {
      selectedSemester = availableSemesters.first;
    }

    final sgpaService = ref.read(sgpaServiceProvider);
    final fetchedSubjects = sgpaService.parseSubjects(sgpaData, userProfile.academicYear, userProfile.branch, selectedSemester);
    _initSubjects(selectedSemester, fetchedSubjects, userMarks);

    final subjectsToDisplay = _localStateSubjects[selectedSemester] ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer, // Slate 50 to match Home Screen
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false, // Match home screen left-aligned title
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'SGPA ',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface, // baseNavy
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(
                text: 'Calc',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary, // nirmaRed
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            // Semester Navigation Tabs

            Center(

              child: Container(

                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(

                  color: const Color(0xFFF8FAFC),

                  borderRadius: BorderRadius.circular(100)
                ),

                child: Row(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    ...availableSemesters.map((sem) => Padding(
                      padding: EdgeInsets.only(right: sem != availableSemesters.last ? 16.0 : 0),
                      child: _buildSemButton(sem, "Sem $sem"),
                    )),
                  ]
                )
              )
            ),

            SizedBox(height: 24),



            // Result Summary Card

            Container(

              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(

                color: theme.colorScheme.error,

                borderRadius: BorderRadius.circular(12),

                boxShadow: [

                  BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),

                    blurRadius: 6,

                    offset: const Offset(0, 4)
                  ),

                ]
              ),

              child: Row(

                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [

                  Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        'Estimated SGPA',

                        style: TextStyle(

                            fontSize: 12,

                            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),

                            fontWeight: FontWeight.w500
                          ), ),

                      SizedBox(height: 4),

                      Text(

                        'Based on targets',

                        style: TextStyle(

                            fontSize: 20,

                            color: Theme.of(context).colorScheme.surface,

                            fontWeight: FontWeight.w600
                          ), ),

                    ]
                  ),

                  Text(
                    _calculateEstimatedSGPA(subjectsToDisplay),
                    style: TextStyle(

                        fontSize: 48,

                        color: Theme.of(context).colorScheme.surface,

                        fontWeight: FontWeight.bold,

                        letterSpacing: -0.02
                      ), ),

                ]
              )
            ),

            SizedBox(height: 24),



            // Subject List Grid / Cards
            ...((subjectsToDisplay).map((subject) {
              return Column(
                children: [
                  _buildSubjectCard(subject),

                  SizedBox(height: 24),

                ]
              );

            })),



            // FAQ Section

            Container(

              decoration: BoxDecoration(

                color: Theme.of(context).colorScheme.surface,

                borderRadius: BorderRadius.circular(12),

                border: Border.all(color: const Color(0xFFCBD5E1))
              ),

              child: ExpansionTile(

                shape: const Border(),

                iconColor: theme.colorScheme.error,

                collapsedIconColor: theme.colorScheme.error,

                title: Text(

                  'Frequently Asked Questions',

                  style: TextStyle(

                      fontSize: 20,

                      fontWeight: FontWeight.bold,

                      color: theme.colorScheme.primaryContainer
                    ), ),

                children: [

                  Padding(

                    padding: const EdgeInsets.all(24.0),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(

                          'How is the calculation done?',

                          style: TextStyle(

                              fontSize: 20,

                              fontWeight: FontWeight.w600,

                              color: theme.colorScheme.error
                            ), ),

                        SizedBox(height: 16),

                        Text(

                          'The calculator uses the official weightage distribution to first determine your current standing (Internal Marks) and then calculates the remaining marks needed in the final exam (SEE) to reach your target grade.',

                          style: TextStyle(

                              fontSize: 14,

                              color: theme.colorScheme.onSurfaceVariant
                            ), ),

                        SizedBox(height: 16),

                        // Calculation Steps Container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              style: BorderStyle.solid,
                            )
                          ),
                          child: Column(
                            children: [
                              _buildStepBox("1. Input Marks", "Sessional, Assignment, Lab, LPW", false),
                              Icon(Icons.arrow_downward, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                              _buildStepBox("2. Calculate Internal (50%)", "Simple: (Sess/50)*25 + (Assgn/50)*25\nComplex: (Sess/50)*15 + (Assgn/50)*10 + (LAB/100)*15 + (LPW/40)*10", false),
                              Icon(Icons.arrow_downward, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                              _buildStepBox("3. Determine Target %", "e.g., Grade 9 = 81% Total Aggregate Required", false),
                              Icon(Icons.arrow_downward, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                              _buildStepBox("4. Final Formula", "", true),
                              SizedBox(height: 8),
                              Text(
                                '(Target % - Internal Marks) × 2 = Required SEE Marks',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold
                                  ), )
                            ]
                          )
                        ),
                        SizedBox(height: 24),
                        Text(
                          'How is ED (EGD) calculated?',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.error
                            ), ),
                        SizedBox(height: 16),
                        Text(
                          'Engineering Graphics & Design (ED) does not have a Semester End Examination (SEE). The final grade is 100% based on your Internal Marks:\n• Sessional: 30%\n• Assignment: 20%\n• Lab Manual: 30%\n• LPW: 20%',
                          style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant
                            ), ),
                      ]
                    )
                  )

                ]
              )
            ),

            SizedBox(height: 24),



            // Query Section

            Container(

              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(

                color: Theme.of(context).colorScheme.surface,

                borderRadius: BorderRadius.circular(12),

                border: Border.all(color: const Color(0xFFCBD5E1))
              ),

              child: Column(

                children: [

                  Text(

                    'Is there any query?',

                    style: TextStyle(

                        fontSize: 20,

                        fontWeight: FontWeight.bold,

                        color: theme.colorScheme.primaryContainer
                      ), ),

                  SizedBox(height: 16),

                  Text(

                    'Click below to send an email directly using your Nirma ID.',

                    textAlign: TextAlign.center,

                    style: TextStyle(

                        fontSize: 14,

                        color: theme.colorScheme.onSurfaceVariant
                      ), ),

                  SizedBox(height: 16),

                  InkWell(

                    onTap: () async {
                      final Uri emailUri = Uri.parse('mailto:backlogon@gmail.com');
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      }
                    },

                    borderRadius: BorderRadius.circular(12),

                    child: Container(

                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(

                        border: Border.all(color: const Color(0xFFCBD5E1)),

                        borderRadius: BorderRadius.circular(12)
                      ),

                      child: Column(

                        children: [

                          Row(

                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [

                              Icon(Icons.mail_outline, color: theme.colorScheme.primary),

                              SizedBox(width: 8),

                              Text(

                                'Mail to',

                                style: TextStyle(

                                    fontSize: 20,

                                    fontWeight: FontWeight.bold,

                                    color: theme.colorScheme.primary
                                  ), ),

                            ]
                          ),

                          SizedBox(height: 4),

                          Text(

                            'backlogon@gmail.com',

                            style: TextStyle(

                                fontSize: 20,

                                fontWeight: FontWeight.bold,

                                color: theme.colorScheme.primary
                              ), ),

                        ]
                      )
                    )
                  )

                ]
              )
            ),

            SizedBox(height: 80), // extra padding for custom bottom nav spacing

          ]
        )
      ),

      bottomNavigationBar: Container(

        height: 64,

        decoration: BoxDecoration(

          color: Theme.of(context).colorScheme.surface,

          border: Border(top: BorderSide(color: Color(0xFFCBD5E1), width: 1))
        ),

        child: Row(

          mainAxisAlignment: MainAxisAlignment.spaceAround,

          children: [

            _buildBottomNavTab(Icons.home_outlined, "Home", 0),

            _buildBottomNavTab(Icons.menu_book_outlined, "Study", 1),

            _buildBottomNavTab(Icons.school_outlined, "Student", 2),

            _buildBottomNavTab(Icons.person_outline, "Profile", 3),

          ]
        )
      )
    );

  }



  Widget _buildSemButton(String semIndex, String label) {

    bool isSelected = selectedSemester == semIndex;

    return ElevatedButton(

      onPressed: () {

        setState(() {

          selectedSemester = semIndex;

        });

      },

      style: ElevatedButton.styleFrom(

        elevation: isSelected ? 4 : 0,

        backgroundColor: isSelected ? const Color(0xFFC62828) : Colors.transparent,

        foregroundColor: isSelected ? Colors.white : const Color(0xFF64748B),

        shadowColor: isSelected ? Colors.black.withOpacity(0.4) : Colors.transparent,

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))
      ).copyWith(

        elevation: ButtonStyleButton.allOrNull(isSelected ? 4 : 0)
      ),

      child: Text(

        label,

        style: TextStyle(

            fontSize: 14,

            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600
          ), )
    );

  }



  Widget _buildSubjectCard(SubjectData subject) {
    final theme = Theme.of(context);
    final Color nirmaRed = const Color(0xFFC62828);
    final Color textDark = const Color(0xFF0F172A);
    final Color textGray = const Color(0xFF64748B);
    final Color borderGray = const Color(0xFFCBD5E1);
    final Color inputFill = const Color(0xFFF8FAFC);
    bool isEGD = subject.title == "EGD";
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 6)),
        ],
        border: Border.all(color: borderGray.withValues(alpha: 0.3))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject.title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark
              ), ),
          SizedBox(height: 20),
          ...subject.rows.map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      row.label,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark), ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: row.controller,
                            keyboardType: TextInputType.number,
                            cursorColor: nirmaRed,
                            style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 15),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: '0',
                              hintStyle: TextStyle(color: textGray.withValues(alpha: 0.6), fontSize: 14),
                              filled: true,
                              fillColor: inputFill,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '/${row.maxMarks}',
                                      style: TextStyle(fontSize: 13, color: textGray)
                                    ),
                                  ]
                                )
                              ),
                              suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: row.error != null ? nirmaRed : borderGray.withValues(alpha: 0.6), width: 1.2)
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: nirmaRed, width: 1.8)
                              )
                            )
                          )
                        ),
                        if (row.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(row.error!, style: TextStyle(color: nirmaRed, fontSize: 11, fontWeight: FontWeight.w500))
                          ),
                      ]
                    )
                  ]
                )
              )),
          SizedBox(height: 16),
          Divider(color: borderGray.withValues(alpha: 0.5), height: 1),
          SizedBox(height: 16),
          if (!isEGD) 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target Grade',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark), ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: subject.targetGradeController,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      cursorColor: nirmaRed,
                      style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 15),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '0',
                        hintStyle: TextStyle(color: textGray.withValues(alpha: 0.6), fontSize: 14),
                        filled: true,
                        fillColor: inputFill,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '/10',
                                style: TextStyle(fontSize: 13, color: textGray)
                              ),
                            ]
                          )
                        ),
                        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: subject.targetGradeError != null ? nirmaRed : borderGray.withValues(alpha: 0.6), width: 1.2)
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: nirmaRed, width: 1.8)
                        )
                      )
                    )
                  ),
                  if (subject.targetGradeError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(subject.targetGradeError!, style: TextStyle(color: nirmaRed, fontSize: 11, fontWeight: FontWeight.w500))
                    ),
                ]
              )
            ]
          ),
          SizedBox(height: 28),
          if (subject.calculatedResult != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: subject.isResultError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: subject.isResultError ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0))
              ),
              child: Text(
                subject.calculatedResult!,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: subject.isResultError ? const Color(0xFF991B1B) : const Color(0xFF166534)
                  ),
                textAlign: TextAlign.center
              )
            ),
            SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  bool hasError = false;

                  if (!isEGD) {
                    if (subject.targetGradeController.text.isEmpty) {
                      subject.targetGradeError = "Required";
                      hasError = true;
                    } else {
                      double? grade = double.tryParse(subject.targetGradeController.text);
                      if (grade == null || grade < 0 || grade > 10) {
                        subject.targetGradeError = "0-10 only";
                        hasError = true;
                      } else {
                        subject.targetGradeError = null;
                      }
                    }
                  } else {
                    subject.targetGradeError = null;
                  }

                  for (var row in subject.rows) {
                    if (row.controller.text.isEmpty) {
                      row.error = "Required";
                      hasError = true;
                    } else {
                      double? val = double.tryParse(row.controller.text);
                      if (val == null || val < 0 || val > row.maxMarks) {
                        row.error = "0-${row.maxMarks}";
                        hasError = true;
                      } else {
                        row.error = null;
                      }
                    }
                  }

                  if (hasError) {
                    subject.isResultError = true;
                    subject.calculatedResult = "Invalid input. Please correct the errors in red before calculating.";
                    return;
                  }
                  
                  subject.isResultError = false;

                  double internalMarks = 0;
                  
                  if (subject.rows.length == 2) {
                    double sess = double.parse(subject.rows[0].controller.text);
                    double assgn = double.parse(subject.rows[1].controller.text);
                    internalMarks = (sess / subject.rows[0].maxMarks) * 25 + (assgn / subject.rows[1].maxMarks) * 25;
                  } else if (subject.rows.length >= 4) {
                    double sess = double.parse(subject.rows[0].controller.text);
                    double assgn = double.parse(subject.rows[1].controller.text);
                    double lab = double.parse(subject.rows[2].controller.text);
                    double lpw = double.parse(subject.rows[3].controller.text);
                    if (isEGD) {
                      internalMarks = (sess / subject.rows[0].maxMarks) * 30 +
                                      (assgn / subject.rows[1].maxMarks) * 20 +
                                      (lab / subject.rows[2].maxMarks) * 30 +
                                      (lpw / subject.rows[3].maxMarks) * 20;
                    } else {
                      internalMarks = (sess / subject.rows[0].maxMarks) * 15 +
                                      (assgn / subject.rows[1].maxMarks) * 10 +
                                      (lab / subject.rows[2].maxMarks) * 15 +
                                      (lpw / subject.rows[3].maxMarks) * 10;
                    }
                  }

                  if (isEGD) {
                      int calculatedGrade = ((internalMarks + 9) / 10).floor();
                      if (calculatedGrade > 10) calculatedGrade = 10;
                      if (internalMarks < 41) calculatedGrade = 0;
                      subject.calculatedResult = "Final Grade: $calculatedGrade (Score: ${internalMarks.toStringAsFixed(1)} / 100)";
                      subject.targetGradeController.text = calculatedGrade.toString();
                  } else {
                      double targetGrade = double.parse(subject.targetGradeController.text);
                      double targetPercentage = (targetGrade * 10) - 9;
                      double requiredSee = (targetPercentage - internalMarks) * 2;
                      
                      if (requiredSee > 100) {
                         subject.calculatedResult = "You need ${requiredSee.toStringAsFixed(1)} marks, which is not possible (max 100).";
                      } else if (requiredSee < 0) {
                         subject.calculatedResult = "You have already achieved the target grade!";
                      } else {
                         subject.calculatedResult = "Minimum Required SEE Marks: ${requiredSee.toStringAsFixed(1)}";
                      }
                  }
                  
                  // Save marks to Supabase
                  final userId = ref.read(authNotifierProvider).value?.id;
                  if (userId != null) {
                    Map<String, String> marksToSave = {};
                    for (var row in subject.rows) {
                      marksToSave[row.label] = row.controller.text;
                    }
                    if (!isEGD) {
                      marksToSave['Target Grade'] = subject.targetGradeController.text;
                    }
                    
                    ref.read(sgpaServiceProvider).saveSubjectMarks(
                      userId: userId,
                      semester: selectedSemester,
                      subjectName: subject.title,
                      marks: marksToSave,
                    );
                  }
                  
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A), // baseNavy
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Matches premium button radii
              ),
              child: Text(
                isEGD ? 'Calculate & Save' : 'Calculate & Save',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), )
            )
          )
        ]
      )
    );
  }
  Widget _buildStepBox(String title, String subtitle, bool isRed) {

    return Container(

      width: double.infinity,

      margin: const EdgeInsets.symmetric(vertical: 4),

      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),

      decoration: BoxDecoration(

        color: isRed ? const Color(0xFFC62828) : Colors.white,

        borderRadius: BorderRadius.circular(8),

        border: isRed ? null : Border.all(color: const Color(0xFFCBD5E1))
      ),

      child: Column(

        children: [

          Text(

            title,

            style: TextStyle(

                fontWeight: FontWeight.bold,

                color: isRed ? Colors.white : const Color(0xFF0F172A)
              ), ),

          if (subtitle.isNotEmpty) ...[

            SizedBox(height: 4),

            Text(

              subtitle,

              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant), ),

          ]

        ]
      )
    );

  }



Widget _buildBottomNavTab(IconData icon, String label, int index) {

    bool isActive = currentBottomNavIndex == index;

    return Expanded(

      child: InkWell(

        onTap: () {

          setState(() {

            currentBottomNavIndex = index;

          });

        },

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(icon, color: isActive ? const Color(0xFFC62828) : const Color(0xFF64748B), size: 20),

            SizedBox(height: 2),

            Text(

              label,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: TextStyle(

                  fontSize: 9,

                  color: isActive ? const Color(0xFFC62828) : const Color(0xFF64748B),

                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500
                ), )

          ]
        )
      )
    );

  }


}

class SubjectRow {

  String label;

  int maxMarks;

  TextEditingController controller;

  String? error;



  SubjectRow({required this.label, required this.maxMarks})

      : controller = TextEditingController();

}



class SubjectData {

  String title;

  List<SubjectRow> rows;

  TextEditingController targetGradeController;

  String? targetGradeError;

  String? calculatedResult;

  bool isResultError = false;



  SubjectData({required this.title, required this.rows})

      : targetGradeController = TextEditingController();

}