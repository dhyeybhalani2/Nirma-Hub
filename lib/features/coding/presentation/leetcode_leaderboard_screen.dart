import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ai/widgets/skeleton_loaders.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../widgets/premium_touch_button.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../domain/coding_profile_model.dart';
import '../data/coding_service.dart';
import 'link_profile_dialog.dart';
import '../../../widgets/link_account_promo_sheet.dart';


class LeetCodeLeaderboardScreen extends ConsumerStatefulWidget {
  const LeetCodeLeaderboardScreen({super.key});

  @override
  ConsumerState<LeetCodeLeaderboardScreen> createState() => _LeetCodeLeaderboardScreenState();
}

class _LeetCodeLeaderboardScreenState extends ConsumerState<LeetCodeLeaderboardScreen> {
  final CodingService _codingService = CodingService();
  bool _isLoading = true;
  List<CodingProfile> _allProfiles = [];
  String _filter = 'All'; // 'All', 'My Branch', 'My Year', 'My Class'
  String _sortBy = 'Rating'; // 'Rating', 'Ranking'
  final TextEditingController _searchController = TextEditingController();
  int _visibleCount = 20;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowPromo();
    });
  }

  Future<void> _checkAndShowPromo() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('has_shown_leetcode_promo') ?? false;
    
    if (!hasShown && mounted) {
      await prefs.setBool('has_shown_leetcode_promo', true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          LinkAccountPromoSheet.show(
            context,
            platform: 'LeetCode',
            primaryColor: const Color(0xFFEF4444), // Same Red
            onLinkPressed: _showLinkDialog,
          );
        }
      });
    }
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    final data = await _codingService.getLeetCodeLeaderboard();
    
    final uniqueData = <String, CodingProfile>{};
    for (var profile in data) {
      uniqueData[profile.id] = profile;
    }
    
    setState(() {
      _allProfiles = uniqueData.values.toList();
      _isLoading = false;
    });
  }

  void _showLinkDialog() async {
    final userState = ref.read(authNotifierProvider);
    final userProfile = userState.value;
    if (userProfile == null) return;

    CodingProfile? currentCodingProfile;
    for (var p in _allProfiles) {
      if (p.id == userProfile.id || p.fullName.toLowerCase().trim() == userProfile.fullName.toLowerCase().trim()) {
        currentCodingProfile = p;
        break;
      }
    }

    final isLinked = currentCodingProfile != null && currentCodingProfile.leetcodeUsername != null;

    if (isLinked) {
      final shouldUnlink = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Linked Account', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'Your LeetCode account is linked as:\n\n${currentCodingProfile!.leetcodeUsername}\n\nDo you want to unlink it?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
              child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Unlink', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (shouldUnlink == true) {
        setState(() => _isLoading = true);
        final success = await _codingService.unlinkLeetCode(userProfile);
        if (success) {
          _fetchLeaderboard();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('LeetCode profile unlinked successfully!')),
            );
          }
        } else {
          setState(() => _isLoading = false);
        }
      }
    } else {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => const LinkProfileDialog(isLeetCode: true),
      );
      if (result == true) {
        _fetchLeaderboard();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.surface, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'LeetCode profile linked successfully!',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.tertiary, // Emerald green success color
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              elevation: 6,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  List<CodingProfile> get _rankedProfiles {
    final userState = ref.read(authNotifierProvider);
    final user = userState.value;

    Iterable<CodingProfile> base = _allProfiles;
    if (_filter != 'All' && user != null) {
      base = base.where((profile) {
        if (_filter == 'My Branch') return profile.branch == user.branch;
        if (_filter == 'My Year') return profile.academicYear == user.academicYear;
        if (_filter == 'My Class') return profile.division == user.division;
        return true;
      });
    }

    final filtered = base.toList();

    filtered.sort((a, b) {
      if (_sortBy == 'Rating') {
        return b.leetcodeRating.compareTo(a.leetcodeRating);
      } else {
        // For Ranking, lower is better. 0 means unranked (put at the bottom).
        if (a.leetcodeRanking == 0 && b.leetcodeRanking == 0) return 0;
        if (a.leetcodeRanking == 0) return 1;
        if (b.leetcodeRanking == 0) return -1;
        return a.leetcodeRanking.compareTo(b.leetcodeRanking);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final ranked = _rankedProfiles;
    final query = _searchController.text.trim().toLowerCase();
    
    final searched = query.isEmpty 
        ? ranked 
        : ranked.where((profile) {
            final name = profile.fullName.toLowerCase();
            final username = (profile.leetcodeUsername ?? '').toLowerCase();
            return name.contains(query) || username.contains(query);
          }).toList();

    final userState = ref.watch(authNotifierProvider);
    final userProfile = userState.value;
    
    bool isMe(CodingProfile p) {
      if (userProfile == null) return false;
      if (p.id == userProfile.id) return true;
      if (p.fullName.toLowerCase().trim() == userProfile.fullName.toLowerCase().trim()) return true;
      return false;
    }
    
    final currentUserIndex = ranked.indexWhere(isMe);
    final bool isLinked = currentUserIndex != -1;
    final displayList = searched.take(_visibleCount).toList();
    final isSearching = query.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer, // Slate 100 bg
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
                onTap: () => Navigator.of(context).pop(),
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
          'LeetCode Leaderboard',
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
        actions: [
          IconButton(
            icon: Icon(Icons.link, color: Theme.of(context).colorScheme.onSurface),
            tooltip: 'Link Profile',
            onPressed: _showLinkDialog,
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by name or username...',
                        prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.tune, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          onPressed: () => _showFilterDialog(context),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: _isLoading
            ? const LeaderboardSkeleton()
            : searched.isEmpty
                ? Center(
                    child: Text(
                      _allProfiles.isEmpty 
                          ? 'No profiles linked yet. Be the first!' 
                          : 'No profiles match your filter or search.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  )
                : Column(
                    children: [
                      if (currentUserIndex != -1 && !isSearching) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: _buildProfileCard(ranked[currentUserIndex], currentUserIndex + 1, isCurrentUser: true, isPinned: true),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(height: 16, thickness: 1, color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                      ],
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(16, (currentUserIndex != -1 && !isSearching) ? 0 : 16, 16, 16),
                          children: [
                            ...displayList.map((profile) {
                              final actualRank = ranked.indexOf(profile) + 1;
                              return _buildProfileCard(profile, actualRank, isCurrentUser: isMe(profile));
                            }),
                            if (_visibleCount < searched.length)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: TextButton(
                                  onPressed: () {
                                    setState(() => _visibleCount += 20);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFC62828),
                                  ),
                                  child: Text('Show More', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  String _getShortBranch(String branch) {
    if (branch.toLowerCase().contains('electrical')) return 'EC';
    if (branch.toLowerCase().contains('computer')) return 'CSE';
    if (branch.toLowerCase().contains('mechanical')) return 'ME';
    if (branch.toLowerCase().contains('civil')) return 'CE';
    if (branch.toLowerCase().contains('chemical')) return 'CH';
    if (branch.toLowerCase().contains('instrumentation')) return 'IC';
    return branch;
  }

  Widget _buildProfileCard(CodingProfile profile, int rank, {bool isCurrentUser = false, bool isPinned = false}) {
    return PremiumTouchButton(
      onTap: () async {
        final url = Uri.parse('https://leetcode.com/u/${profile.leetcodeUsername}/');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      },
      child: Container(
        margin: isPinned ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isCurrentUser ? const Color(0xFFFEF2F2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(
            color: isCurrentUser ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
            width: isCurrentUser ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Rank Number
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rank <= 3 
                    ? const Color(0xFFFEF2F2) 
                    : const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(
                  color: rank <= 3 
                      ? const Color(0xFFFCA5A5) 
                      : const Color(0xFFE2E8F0)
                ),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 
                        ? const Color(0xFFDC2626) 
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCurrentUser ? '${profile.fullName} (You)' : profile.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isCurrentUser ? const Color(0xFFC62828) : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '@${profile.leetcodeUsername}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile.branch != null) ...[
                    Text(
                      '${profile.academicYear != null && profile.academicYear!.isNotEmpty ? "${profile.academicYear} Year" : ""} • ${_getShortBranch(profile.branch ?? "")} • ${profile.division ?? ""}'.replaceAll(RegExp(r'^[ •]+|[ •]+$'), '').replaceAll(' •  • ', ' • '),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]
                ],
              ),
            ),
          
          // Dynamic Badge (Rating or Ranking)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _sortBy == 'Rating' ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _sortBy == 'Rating' ? const Color(0xFFBBF7D0) : const Color(0xFFFED7AA),
              ),
            ),
            child: Column(
              children: [
                Text(
                  _sortBy == 'Rating' 
                      ? '${(profile.leetcodeRating as num) > 0 ? profile.leetcodeRating : 'N/A'}' 
                      : (profile.leetcodeRanking > 0 ? '#${profile.leetcodeRanking}' : 'N/A'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _sortBy == 'Rating' ? const Color(0xFF166534) : const Color(0xFF9A3412),
                    fontSize: _sortBy == 'Rating' ? 16 : 14,
                  ),
                ),
                Text(
                  _sortBy == 'Rating' ? 'Rating' : 'Global Rank',
                  style: TextStyle(
                    fontSize: 10,
                    color: _sortBy == 'Rating' ? const Color(0xFF166534) : const Color(0xFF9A3412),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Text('Filter by:', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', 'My Branch', 'My Year', 'My Class'].map((filterName) {
                      final isSelected = _filter == filterName;
                      return ChoiceChip(
                        label: Text(filterName),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setSheetState(() => _filter = filterName);
                            setState(() => _filter = filterName);
                          }
                        },
                        selectedColor: const Color(0xFFFEF2F2),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFFC62828) : const Color(0xFF64748B),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),
                  Text('Sort by:', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'Rating', label: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Rating', style: TextStyle(fontSize: 12)))),
                      ButtonSegment(value: 'Ranking', label: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Global Rank', style: TextStyle(fontSize: 12)))),
                    ],
                    selected: {_sortBy},
                    onSelectionChanged: (newSelection) {
                      setSheetState(() => _sortBy = newSelection.first);
                      setState(() => _sortBy = newSelection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      selectedBackgroundColor: const Color(0xFFFEF2F2),
                      selectedForegroundColor: const Color(0xFFC62828),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }
}
