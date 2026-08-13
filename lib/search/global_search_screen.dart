import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ai/notes_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allMaterials = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      final client = Supabase.instance.client;
      // Fetch concurrently for speed
      final results = await Future.wait([
        client.from('subjects').select('id, name, code'),
        client.from('materials').select('*'),
      ]);
      
      final subjectsList = List<Map<String, dynamic>>.from(results[0]);
      final materialsList = List<Map<String, dynamic>>.from(results[1]);
      
      // Build lookup map
      final subjectMap = <String, Map<String, dynamic>>{};
      for (var s in subjectsList) {
        subjectMap[s['id'].toString()] = s;
      }
      
      // Attach subject info to materials
      for (var m in materialsList) {
        final subId = m['subject_id']?.toString();
        if (subId != null && subjectMap.containsKey(subId)) {
          m['subject_name'] = subjectMap[subId]!['name'];
          m['subject_code'] = subjectMap[subId]!['code'];
        } else {
          m['subject_name'] = '';
          m['subject_code'] = '';
        }
      }
      
      if (mounted) {
        setState(() {
          _allMaterials = materialsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading search data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    
    // Filter entirely in memory for zero lag
    final results = _allMaterials.where((m) {
      final fileName = (m['file_name']?.toString() ?? '').toLowerCase();
      final folderType = (m['folder_type']?.toString() ?? '').toLowerCase();
      final subjectName = (m['subject_name']?.toString() ?? '').toLowerCase();
      final subjectCode = (m['subject_code']?.toString() ?? '').toLowerCase();
      
      return fileName.contains(lowerQuery) || 
             folderType.contains(lowerQuery) || 
             subjectName.contains(lowerQuery) || 
             subjectCode.contains(lowerQuery);
    }).toList();

    setState(() {
      _searchResults = results;
    });
  }

  void _openPdf(Map<String, dynamic> item) {
    final urlStr = item['drive_url']?.toString() ?? '';
    final fileName = item['file_name']?.toString() ?? 'Document';
    
    if (urlStr.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            pdfTitle: fileName.length > 30 ? "${fileName.substring(0, 30)}..." : fileName,
            pdfUrl: urlStr,
            pdfType: 'Note',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer, // Match standard BG
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
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(CupertinoIcons.search, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _performSearch,
                  decoration: InputDecoration(
                    hintText: 'Search Notes, PYQs, Topics...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant, 
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Manrope',
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface, 
                    fontSize: 14, 
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                  child: Icon(CupertinoIcons.clear_thick_circled, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
                ),
            ],
          ),
        ),
        actions: [SizedBox(width: 16)], // Right padding to balance the layout
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : _searchResults.isEmpty && _searchController.text.isNotEmpty
          ? _buildEmptyState()
          : _searchController.text.isEmpty
              ? _buildInitialState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return _buildSearchResultCard(item);
                  },
                ),
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> item) {
    final fileName = item['file_name']?.toString() ?? '';
    final subjectName = item['subject_name']?.toString() ?? '';
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    final isPpt = fileName.toLowerCase().endsWith('.ppt') || fileName.toLowerCase().endsWith('.pptx');
    
    IconData icon = CupertinoIcons.doc_text_fill;
    Color iconColor = const Color(0xFFE11D48); // default red
    
    if (isPpt) {
      icon = Icons.slideshow;
      iconColor = const Color(0xFFF57C00); // orange for ppt
    } else if (isPdf) {
      icon = CupertinoIcons.doc_text_fill;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openPdf(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (subjectName.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          subjectName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                Icon(CupertinoIcons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.search, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
          SizedBox(height: 16),
          Text(
            'Search Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Find your notes, PPTs, or PDFs instantly',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.doc_text_search, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
          SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try searching for different keywords',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
