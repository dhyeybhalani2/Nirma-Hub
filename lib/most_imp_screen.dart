import 'package:flutter/material.dart';
import 'search_helper.dart';
import 'package:flutter/cupertino.dart';
import 'widgets/premium_touch_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'subjects_data.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

// ─────────────────────────────────────────────
// Most IMP Screen Features & Data Models
// ─────────────────────────────────────────────
const Color _baseNavy   = Color(0xFF0F172A);
const Color _nirmaRed   = Color(0xFFC62828);
const Color _textGray   = Color(0xFF64748B);
const Color _borderGray = Color(0xFFE2E8F0);
const Color _bgSurface  = Color(0xFFF1F4F9);
const Color _scaffold   = Color(0xFFF1F4F9);

class MostImpScreen extends ConsumerStatefulWidget {
  const MostImpScreen({super.key});

  @override
  ConsumerState<MostImpScreen> createState() => _MostImpScreenState();
}

class _MostImpScreenState extends ConsumerState<MostImpScreen> {
  String _searchQuery = '';

  final List<SubjectItem> _subjects = parsedSubjectsData;

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(authNotifierProvider).value;
    final isFirstYear = userProfile?.academicYear == '1st';

    if (!isFirstYear) {
      return Scaffold(
        backgroundColor: _scaffold,
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
                    child: Icon(CupertinoIcons.arrow_left, color: _baseNavy, size: 18),
                  ),
                ),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _borderGray, height: 1),
          ),
          title: Text("Most IMP", style: TextStyle(color: _baseNavy, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5, fontFamily: 'Manrope')),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.folder_open, size: 64, color: _textGray),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "There is no IMP Uploaded for current year",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _baseNavy, fontFamily: 'Manrope'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Filter subjects based on query
    final filteredSubjects = _subjects.where((subject) {
      final shortForm = generateShortForm(subject.name);
      return subject.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          subject.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          shortForm.contains(_searchQuery.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''));
    }).toList();

    return Scaffold(
      backgroundColor: _scaffold,
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
                  child: Icon(CupertinoIcons.arrow_left, color: _baseNavy, size: 18),
                ),
              ),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _borderGray, height: 1),
        ),
        title: Text(
          'Most IMP Topics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _baseNavy,
            letterSpacing: -0.5,
            fontFamily: 'Manrope',
          ),
        ),
      ),
      body: Container(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 450,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            children: [
              _buildSearchBar(),
              SizedBox(height: 20),
              _buildSubjectsList(filteredSubjects),
              SizedBox(height: 60),
            ],
          ),
        ),
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
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _baseNavy, fontFamily: 'Manrope'),
      cursorColor: _nirmaRed,
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

  Widget _buildSubjectsList(List<SubjectItem> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: _borderGray, width: 1.5),
              ),
              child: Icon(
                CupertinoIcons.square_grid_2x2,
                color: _textGray,
                size: 32,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'No subjects found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _baseNavy,
                fontFamily: 'Manrope',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textGray,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final subject = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _SubjectListCard(
            subject: subject,
            onTap: () {
              Future.delayed(const Duration(milliseconds: 120), () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => SubjectQuestionsScreen(subject: subject)),
                );
              });
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------------------------------------
// Subject Grid Card (Box Style)
// ---------------------------------------------------------------------------------------------------------
class _SubjectListCard extends StatelessWidget {
  final SubjectItem subject;
  final VoidCallback onTap;

  const _SubjectListCard({required this.subject, required this.onTap});

  Color _getIconColorForSubject(String name) {
    final hash = name.hashCode.abs();
    final colors = [
      const Color(0xFF388E3C), const Color(0xFF1976D2), const Color(0xFF7B1FA2),
      const Color(0xFFF57C00), const Color(0xFF0097A7), const Color(0xFFC2185B), 
      const Color(0xFF3F51B5), const Color(0xFFD84315), const Color(0xFFC62828)
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColorForSubject(subject.name);
    return PremiumTouchButton(
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
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Icon(subject.icon, color: iconColor, size: 20),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
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
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              subject.code,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontFamily: 'Manrope',
                              ),
                            ),
                            if (subject.topicCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${subject.topicCount} Topics',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: iconColor,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                          ],
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
    );
  }
}

// ─────────────────────────────────────────────
// Subject Questions Screen
// ─────────────────────────────────────────────
class SubjectQuestionsScreen extends StatelessWidget {
  final SubjectItem subject;
  const SubjectQuestionsScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffold,
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
                  child: Icon(CupertinoIcons.arrow_left, color: _baseNavy, size: 18),
                ),
              ),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _borderGray, height: 1),
        ),
        title: Text(
          subject.name,
          style: TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w900, color: _baseNavy),
        ),
      ),
      body: Container(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 450,
          child: ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: subject.units.length,
            itemBuilder: (context, unitIdx) {
              final unit = subject.units[unitIdx];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                    child: Text(
                      unit.title.toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _textGray, letterSpacing: 1.2, fontFamily: 'Manrope'),
                    ),
                  ),
                  ...unit.questions.map((q) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _QuestionRowCard(
                      question: q,
                      subject: subject,
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) => QuestionDetailDialog(question: q, subject: subject),
                        );
                      },
                    ),
                  )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Question Row Card (Horizontal)
// ─────────────────────────────────────────────
class _QuestionRowCard extends StatelessWidget {
  final QuestionItem question;
  final SubjectItem subject;
  final VoidCallback onTap;

  const _QuestionRowCard({required this.question, required this.subject, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumTouchButton(
      enableRipple: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderGray, width: 1.0),
          boxShadow: [BoxShadow(color: _baseNavy.withValues(alpha: 0.015), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            splashColor: const Color(0xFFC62828).withValues(alpha: 0.10),
            highlightColor: const Color(0xFFC62828).withValues(alpha: 0.05),
            onTap: () {
              Future.delayed(const Duration(milliseconds: 120), onTap);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _nirmaRed.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(CupertinoIcons.bolt_fill, color: _nirmaRed, size: 18),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.title,
                    style: TextStyle(
                      fontSize: 14.5, 
                      fontWeight: FontWeight.w600, 
                      color: _baseNavy, 
                      height: 1.5, 
                      fontFamily: 'Manrope'
                    ),
                  ),
                  if (question.badges.isNotEmpty || question.years.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...question.badges.map((badge) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badge == 'High Yield' || badge == 'Top Repeat' || badge == 'Repeat'
                                ? const Color(0xFFE8F5E9)
                                : _baseNavy.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: badge == 'High Yield' || badge == 'Top Repeat' || badge == 'Repeat'
                                  ? const Color(0xFF2E7D32)
                                  : _baseNavy,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        )),
                        if (question.years.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECEFF1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              question.years.length > 20 ? '${question.years.substring(0, 18)}...' : question.years,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF37474F),
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, color: _textGray.withValues(alpha: 0.5), size: 14),
          ],
        ),
              ),
            ),
          ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Question Detail Dialog (Market detail style)
// ─────────────────────────────────────────────
class QuestionDetailDialog extends StatelessWidget {
  final QuestionItem question;
  final SubjectItem subject;

  const QuestionDetailDialog({super.key, required this.question, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 24,
      shadowColor: _baseNavy.withValues(alpha: 0.15),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header matching red and white theme
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(bottom: BorderSide(color: _borderGray, width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _nirmaRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        subject.code,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _nirmaRed, fontFamily: 'Manrope'),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      question.title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _baseNavy, height: 1.4, fontFamily: 'Manrope'),
                    ),
                    if (question.badges.isNotEmpty) ...[
                      SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: question.badges.map((badge) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _nirmaRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _nirmaRed, fontFamily: 'Manrope'),
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (question.years.isNotEmpty) ...[
                      Text('Exam History',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _baseNavy, fontFamily: 'Manrope')),
                      SizedBox(height: 6),
                      Text(
                        question.years,
                        style: TextStyle(fontSize: 12.5, height: 1.5, fontWeight: FontWeight.w600, color: _textGray, fontFamily: 'Manrope'),
                      ),
                      SizedBox(height: 16),
                    ],
                    if (question.answer.isNotEmpty) ...[
                      Text('Detailed Solution / Method',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _baseNavy, fontFamily: 'Manrope')),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _bgSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderGray),
                        ),
                        child: Text(
                          question.answer,
                          style: TextStyle(fontSize: 12.5, height: 1.5, fontWeight: FontWeight.w500, color: _baseNavy, fontFamily: 'Manrope'),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                    if (question.formula.isNotEmpty) ...[
                      Text('Key Formulas & Concepts',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _baseNavy, fontFamily: 'Manrope')),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                        ),
                        child: Text(
                          question.formula,
                          style: TextStyle(fontSize: 12.5, height: 1.5, fontWeight: FontWeight.w700, color: Color(0xFF166534), fontFamily: 'Manrope'),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                    if (question.links.isNotEmpty) ...[
                      Text('Study Resource Links',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _baseNavy, fontFamily: 'Manrope')),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: question.links.map((link) {
                          final label = link["label"] ?? "View PDF";
                          final url = link["url"] ?? "";
                          return OutlinedButton.icon(
                            onPressed: () async {
                              if (url.isNotEmpty) {
                                final Uri pdfUri = Uri.parse(url);
                                if (!await launchUrl(pdfUri)) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Could not open PDF')),
                                    );
                                  }
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('No PDF link available')),
                                );
                              }
                            },
                            icon: Icon(CupertinoIcons.doc_text_search, size: 14),
                            label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'Manrope')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _nirmaRed,
                              side: BorderSide(color: _nirmaRed, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 24),
                    ],
                    // Action Button (Close styled to theme)
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _nirmaRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Close',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, fontFamily: 'Manrope')),
                      ),
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
}

// ─────────────────────────────────────────────
// Study Group Chat Screen (Matches Marketplace Chat)
// ─────────────────────────────────────────────
class StudyGroupChatScreen extends StatefulWidget {
  final String subjectName;
  final String questionTitle;

  const StudyGroupChatScreen({super.key, required this.subjectName, required this.questionTitle});

  @override
  State<StudyGroupChatScreen> createState() => _StudyGroupChatScreenState();
}

class _StudyGroupChatScreenState extends State<StudyGroupChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {'sender': 'Karan Mehta', 'text': 'Has anyone drawn the state transitions for Red-Black tree insertions?', 'isMe': false, 'time': '02:30 PM'},
    {'sender': 'Aditi Shah', 'text': 'Yes, check the textbook page 224. Case 2 (uncle is red) is the trickiest one.', 'isMe': false, 'time': '02:32 PM'},
    {'sender': 'Rohan Patel', 'text': 'Remember, if uncle is black, we always have to perform rotations.', 'isMe': false, 'time': '02:35 PM'},
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({
        'sender': 'Me',
        'text': text,
        'isMe': true,
        'time': _currentTime(),
      });
    });
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _currentTime() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 0,
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
                  child: Icon(CupertinoIcons.arrow_left, color: _baseNavy, size: 18),
                ),
              ),
            ),
          ),
        ),
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Text(
                '${widget.subjectName} Discussion',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _baseNavy,
                  fontFamily: 'Manrope',
                ),
              ),
              SizedBox(height: 2),
              Text(
                widget.questionTitle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: _textGray,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.info_circle, color: _baseNavy, size: 22),
            onPressed: () {},
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Container(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 450,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final msg = _messages[i];
                    final bool isMe = msg['isMe'] == true;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? _nirmaRed : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(color: _baseNavy.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isMe)
                              Text(
                                msg['sender'],
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: _nirmaRed,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            if (!isMe) SizedBox(height: 2),
                            Text(
                              msg['text'],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isMe ? Colors.white : _baseNavy,
                                fontFamily: 'Manrope',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              msg['time'],
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isMe ? Colors.white.withValues(alpha: 0.7) : _textGray,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                color: Theme.of(context).colorScheme.surface,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _bgSurface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _sendMessage(),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _baseNavy, fontFamily: 'Manrope'),
                          decoration: const InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: TextStyle(color: _textGray, fontSize: 13, fontWeight: FontWeight.w600),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _nirmaRed,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(CupertinoIcons.paperplane_fill, color: Theme.of(context).colorScheme.surface, size: 18),
                        ),
                      ),
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
}
