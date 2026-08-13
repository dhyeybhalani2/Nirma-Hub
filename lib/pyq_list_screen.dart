import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/skeleton_loaders.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notes_screen.dart';
import 'widgets/contribution_bottom_sheet.dart';

class PyqListScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String specialThanks;

  const PyqListScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.specialThanks,
  });

  @override
  State<PyqListScreen> createState() => _PyqListScreenState();
}

class _PyqListScreenState extends State<PyqListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pyqs = [];

  @override
  void initState() {
    super.initState();
    _fetchPyqs();
  }

  Future<void> _fetchPyqs() async {
    try {
      final response = await Supabase.instance.client
          .from('pyqs')
          .select('*')
          .eq('subject_id', widget.subjectId)
          .order('exam_year', ascending: false);

      if (mounted) {
        setState(() {
          _pyqs = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching PYQs: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openDriveLink(String url, String fileName, {DateTime? timestamp}) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          pdfTitle: fileName,
          pdfUrl: url,
          pdfType: 'PYQ',
          pdfTimestamp: timestamp,
        ),
      ),
    );
  }

  String _formatYear(String yearStr) {
    yearStr = yearStr.trim();
    if (yearStr.length == 4 && int.tryParse(yearStr) != null) {
      int year = int.parse(yearStr);
      int nextYear = (year + 1) % 100;
      return "$year-${nextYear.toString().padLeft(2, '0')}";
    }
    return yearStr;
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectCode,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Manrope',
              ),
            ),
            Text(
              widget.subjectName,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return SubjectInfoBottomSheet(
                    subjectId: widget.subjectId,
                    subjectName: widget.subjectName,
                    subjectCode: widget.subjectCode,
                    tableName: 'pyqs',
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const ListSkeleton()
          : _pyqs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_edu, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        "No PYQs Available",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey[800],
                          fontFamily: 'Manrope',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Check back later for updates.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pyqs.length,
                  itemBuilder: (context, index) {
                    final pyq = _pyqs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.picture_as_pdf_rounded, color: Theme.of(context).colorScheme.error),
                        ),
                        title: Row(
                          children: [
                            Text(
                              _formatYear(pyq['exam_year'] ?? 'Unknown Year'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                pyq['exam_type'] ?? 'EXAM',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Branch: ${pyq['paper_branch'] ?? 'Unknown'}",
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                              ),
                              SizedBox(height: 12),
                              InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Solution coming soon!"),
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lightbulb_outline, size: 14, color: Theme.of(context).colorScheme.onSurface),
                                      SizedBox(width: 6),
                                      Text(
                                        "View Solution",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 4),
                            ],
                          ),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFCBD5E1)),
                        onTap: () {
                          _openDriveLink(pyq['drive_url'] ?? '', "${_formatYear(pyq['exam_year'] ?? 'PYQ')} - ${pyq['exam_type'] ?? 'Paper'}");
                        },
                      ),
                    );
                  },
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                    isPyq: true,
                  );
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_rounded, color: Theme.of(context).colorScheme.error, size: 20),
                  SizedBox(width: 8),
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
