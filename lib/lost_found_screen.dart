import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;

import 'package:ai/widgets/skeleton_loaders.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/image_compressor.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/lost_and_found/domain/lost_and_found_item.dart';
import 'widgets/premium_touch_button.dart';
import 'features/lost_and_found/presentation/providers/lost_and_found_provider.dart';
import 'features/moderation/presentation/providers/moderation_provider.dart';

class LostAndFoundPage extends ConsumerStatefulWidget {
  const LostAndFoundPage({super.key});

  @override
  ConsumerState<LostAndFoundPage> createState() => _LostAndFoundPageState();
}

class _LostAndFoundPageState extends ConsumerState<LostAndFoundPage> {
  int currentBottomNavIndex = 0;
  int _selectedTabIndex = 0;
  bool _isSearching = false;
  String _searchQuery = "";

    final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LostAndFoundItem> _getFilteredItems(List<LostAndFoundItem> items, int tabIndex) {
    final query = _searchQuery.toLowerCase().trim();
    return items.where((item) {
      final titleLower = item.title.toLowerCase();
      final matchesSearch = query.isEmpty ||
                            titleLower.startsWith(query) ||
                            titleLower.contains(' $query');
      bool matchesTab;
      if (tabIndex == 0) {
        matchesTab = item.isLost && !item.isSuccessful;
      } else if (tabIndex == 1) {
        matchesTab = !item.isLost && !item.isSuccessful;
      } else {
        matchesTab = item.isSuccessful;
      }
      return matchesSearch && matchesTab;
    }).toList();
  }

  void _showReportContentDialog(LostAndFoundItem item) {
    String selectedReason = 'Inappropriate content';
    final reasons = ['Inappropriate content', 'Spam', 'Scam', 'Other'];
    final otherReasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Report Item', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...reasons.map((reason) {
                      return RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                          });
                        },
                        activeColor: const Color(0xFFC62828),
                      );
                    }),
                    if (selectedReason == 'Other')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: TextField(
                          controller: otherReasonController,
                          decoration: InputDecoration(
                            hintText: 'Please specify...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedReason == 'Other' && otherReasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please specify the reason')),
                      );
                      return;
                    }
                    Navigator.pop(context); // Close dialog
                    try {
                      final finalReason = selectedReason == 'Other' ? 'Other: ${otherReasonController.text.trim()}' : selectedReason;
                      await ref.read(moderationServiceProvider).reportItem(
                        reportedUserId: item.userId,
                        itemType: 'lost_found',
                        itemId: item.id,
                        reason: finalReason,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Report submitted successfully')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to submit report: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828), foregroundColor: Colors.white),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _blockUser(String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Block User?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to block this user? You will no longer see their items.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop(); // Close dialog
                try {
                  await ref.read(blockedUsersProvider.notifier).blockUser(userId);
                  if (mounted) {
                    navigator.pop(); // Close detail view
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User blocked successfully')),
                    );
                    ref.read(lostAndFoundItemsProvider.notifier).filterBlockedUserLocally(userId);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to block user: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828), foregroundColor: Colors.white),
              child: const Text('Block'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
      backgroundColor: const Color(0xFFF1F4F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 8,
        leadingWidth: 60,
        automaticallyImplyLeading: !_isSearching,
        leading: _isSearching 
          ? Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        _searchQuery = "";
                      });
                    },
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(CupertinoIcons.arrow_left, color: Color(0xFF0F172A), size: 18),
                    ),
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(CupertinoIcons.arrow_left, color: Color(0xFF0F172A), size: 18),
                    ),
                  ),
                ),
              ),
            ),
        title: _isSearching
          ? Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F9), // Flat grey background
                borderRadius: BorderRadius.circular(24), // Pill shape
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                cursorColor: const Color(0xFF0F172A),
                decoration: InputDecoration(
                  hintText: "Search Lost, Found...",
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15, fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF64748B), size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel, color: Color(0xFF94A3B8), size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = "";
                            });
                          },
                        )
                      : null,
                ),
              ),
            )
          : const Text(
              "Lost & Found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
                fontFamily: 'Manrope',
              ),
            ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(
                Icons.search,
                color: Color(0xFF0F172A),
              ),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            ),
            child: TabBar(
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
                Tab(text: "LOST"),
                Tab(text: "FOUND"),
                Tab(text: "SUCCESSFUL"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        physics: const BouncingScrollPhysics(),
        children: [0, 1, 2].map((tabIndex) {
          return RefreshIndicator(
            color: const Color(0xFFC62828),
            onRefresh: () async {
              return ref.refresh(lostAndFoundItemsProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverPadding(padding: EdgeInsets.only(top: 16)),
                ref.watch(lostAndFoundItemsProvider).when(
                  data: (items) {
                    final filtered = _getFilteredItems(items, tabIndex);
                    if (filtered.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              "No items found.",
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildItemCard(filtered[index]);
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const P2PSkeleton(),
                  error: (err, stack) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(child: Text("Error loading items: ", style: const TextStyle(color: Colors.red))),
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.only(bottom: 80),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReportDialog(context),
        backgroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Report Item",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Manrope',
          ),
        ),
        elevation: 4,
      ),
    ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isSelected ? const Color(0xFFC62828) : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isSelected ? 30 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFFC62828),
                borderRadius: BorderRadius.circular(2),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(LostAndFoundItem item) {
    return PremiumTouchButton(
      onTap: () {
        _showItemDetails(context, item);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5), width: 1),
          boxShadow: [
            BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.imagePath.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: item.imagePath,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: 100,
                          height: 100,
                          color: const Color(0xFFF1F4F9),
                          child: const Icon(Icons.image_not_supported, color: Color(0xFF94A3B8)),
                        ),
                      )
                    : Image.file(
                        File(item.imagePath),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 100,
                          color: const Color(0xFFF1F4F9),
                          child: const Icon(Icons.broken_image, color: Color(0xFF94A3B8)),
                        ),
                      ),
                ),
                if (item.isSuccessful)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.isLost 
                            ? const Color(0xFFFEF2F2) 
                            : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.isLost ? "Lost" : "Found",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.isLost ? const Color(0xFFC62828) : const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        item.date.split(',').first,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context, LostAndFoundItem item) {
    final currentUserId = ref.read(authNotifierProvider).value?.id;
    final isMine = item.userId == currentUserId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 1.0,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    item.imagePath.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: item.imagePath,
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            height: 300,
                            width: double.infinity,
                            color: const Color(0xFFF1F4F9),
                            child: const Center(
                              child: Icon(Icons.image_not_supported, color: Color(0xFF94A3B8), size: 64),
                            ),
                          ),
                        )
                      : Image.file(
                          File(item.imagePath),
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 300,
                            width: double.infinity,
                            color: const Color(0xFFF1F4F9),
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Color(0xFF94A3B8), size: 64),
                            ),
                          ),
                        ),
                    if (!isMine)
                      Positioned(
                        top: 16,
                        right: 68,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                          position: PopupMenuPosition.under,
                          onSelected: (value) {
                            if (value == 'report') {
                              _showReportContentDialog(item);
                            } else if (value == 'block') {
                              _blockUser(item.userId);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'report',
                              child: Row(
                                children: [
                                  Icon(Icons.flag_outlined, size: 20, color: Color(0xFF0F172A)),
                                  SizedBox(width: 12),
                                  Text('Report Item', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'block',
                              child: Row(
                                children: [
                                  Icon(Icons.block, size: 20, color: Color(0xFFC62828)),
                                  SizedBox(width: 12),
                                  Text('Block User', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFC62828))),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.more_vert, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog.fullscreen(
                              backgroundColor: Colors.black,
                              child: Stack(
                                children: [
                                  Center(
                                    child: InteractiveViewer(
                                      child: item.imagePath.startsWith('http')
                                          ? CachedNetworkImage(
                                              imageUrl: item.imagePath,
                                              errorWidget: (context, url, error) => const Center(
                                                child: Icon(Icons.image_not_supported, color: Color(0xFF94A3B8), size: 64),
                                              ),
                                            )
                                          : Image.file(
                                              File(item.imagePath),
                                              errorBuilder: (context, error, stackTrace) => const Center(
                                                child: Icon(Icons.broken_image, color: Color(0xFF94A3B8), size: 64),
                                              ),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 40,
                                    right: 16,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fullscreen, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: item.isLost ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.isLost ? "Lost" : "Found",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: item.isLost ? const Color(0xFFC62828) : const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Description",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: const TextStyle(fontSize: 16, color: Color(0xFF475569), height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFEF2F2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person_outline, size: 24, color: Color(0xFFC62828)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${item.isLost ? 'Lost by' : 'Found by'}",
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.personName,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (!item.isSuccessful) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFEF2F2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.phone_outlined, size: 24, color: Color(0xFFC62828)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Contact Number",
                                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.contactNumber.isNotEmpty ? item.contactNumber : "Not provided",
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (item.email.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFEF2F2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.email_outlined, size: 24, color: Color(0xFFC62828)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Email Address",
                                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.email,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 22, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.location,
                              style: const TextStyle(fontSize: 16, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled, size: 22, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.date,
                              style: const TextStyle(fontSize: 16, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      if (!item.isSuccessful && isMine) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(lostAndFoundNotifierProvider.notifier).markAsSuccessful(item.id);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text("Mark as Successful", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ] else ...[
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        },
        );
      },
    );
  }

  Widget _buildBottomNavTab(IconData outlineIcon, IconData filledIcon, String label, int index) {
    bool isActive = currentBottomNavIndex == index;
    final activeColor = const Color(0xFFC62828); // Red
    final inactiveColor = const Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            currentBottomNavIndex = index;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? filledIcon : outlineIcon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFFC62828),
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportItemBottomSheet(ref: ref),
    );
  }
}

class _ReportItemBottomSheet extends StatefulWidget {
  final dynamic ref;
  const _ReportItemBottomSheet({required this.ref});

  @override
  State<_ReportItemBottomSheet> createState() => _ReportItemBottomSheetState();
}

class _ReportItemBottomSheetState extends State<_ReportItemBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final dateController = TextEditingController();
  late final TextEditingController personNameController;
  final contactController = TextEditingController();
  final emailController = TextEditingController();
  
  String? selectedImagePath;
  bool hasAttemptedSubmit = false;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    final user = widget.ref.read(authNotifierProvider).value;
    personNameController = TextEditingController(text: user?.fullName ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    dateController.dispose();
    personNameController.dispose();
    contactController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Color get currentColor => _tabController.index == 0 ? const Color(0xFFC62828) : const Color(0xFF10B981);
  Color get softColor => _tabController.index == 0 ? const Color(0xFFC62828).withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1);

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, String? hintText, bool readOnly = false, VoidCallback? onTap, String? errorText, TextInputType? keyboardType, int? maxLength, }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        onChanged: (val) {
          if (hasAttemptedSubmit) setState(() {});
        },
        cursorColor: const Color(0xFF0F172A),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          counterText: "",
          labelStyle: TextStyle(
            fontSize: 16,
            color: errorText != null ? const Color(0xFFC62828) : const Color(0xFF64748B),
          ),
          floatingLabelStyle: TextStyle(
            fontSize: 16,
            color: WidgetStateColor.resolveWith((states) {
              if (errorText != null) return const Color(0xFFC62828);
              if (states.contains(WidgetState.focused)) return currentColor;
              return const Color(0xFF0F172A);
            }),
            fontWeight: FontWeight.w600,
          ),
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Colors.white,
          errorText: errorText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorText != null ? Colors.red : const Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorText != null ? Colors.red : Colors.black)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: currentColor, width: 2.0)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    String? getContactError() {
      if (!hasAttemptedSubmit) return null;
      String text = contactController.text.trim();
      if (text.isEmpty) return "Required";
      if (RegExp(r'^\d{10}$').hasMatch(text)) return null;
      if (RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$').hasMatch(text)) return null;
      if (text.contains(RegExp(r'[A-Z]'))) return "Lowercase only";
      return "Invalid format";
    }

    return Container(
      margin: EdgeInsets.only(top: kToolbarHeight),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F4F9), // Exam popup background
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 0),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E6EE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Exam-style Title Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: softColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _tabController.index == 0 ? Icons.campaign_rounded : Icons.check_circle_rounded,
                    color: currentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Report an Item",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F1A2C),
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E6EE).withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF0F1A2C),
                      size: 16,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // TabBar (Like Main Screen)
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              splashFactory: NoSplash.splashFactory,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: currentColor,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'Manrope'),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Manrope'),
              indicatorColor: currentColor,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(text: "I LOST SOMETHING"),
                Tab(text: "I FOUND SOMETHING"),
              ],
            ),
          ),
          
          // Scrollable Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: bottomInset + 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField("Item Name", titleController, hintText: "e.g. Black Wallet", errorText: hasAttemptedSubmit && titleController.text.trim().isEmpty ? "Required" : null),
                  _buildTextField("Description", descriptionController, maxLines: 3, maxLength: 200, hintText: "Describe the item in detail", errorText: hasAttemptedSubmit && descriptionController.text.trim().isEmpty ? "Required" : null),
                  _buildTextField("Location", locationController, maxLength: 50, hintText: "e.g. Near Canteen", errorText: hasAttemptedSubmit && locationController.text.trim().isEmpty ? "Required" : null),
                  _buildTextField("Date & Time", dateController, hintText: "Select date and time", readOnly: true, errorText: hasAttemptedSubmit && dateController.text.trim().isEmpty ? "Required" : null, onTap: () async {
                    DateTime? pickedDate;
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _CustomDatePickerBottomSheet(
                        initialDate: DateTime.now(),
                        themeColor: currentColor,
                        onDateChanged: (date) => pickedDate = date,
                      ),
                    );
                    
                    if (pickedDate != null && context.mounted) {
                      final now = DateTime.now();
                      if (pickedDate!.isAfter(DateTime(now.year, now.month, now.day))) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot select a future date")));
                         return;
                      }
                      
                      TimeOfDay? pickedTime;
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => _CustomTimePickerBottomSheet(
                          initialTime: TimeOfDay.now(),
                          themeColor: currentColor,
                          onTimeChanged: (time) => pickedTime = time,
                        ),
                      );
                      
                      if (pickedTime != null) {
                        final now = DateTime.now();
                        if (pickedDate!.year == now.year && pickedDate!.month == now.month && pickedDate!.day == now.day) {
                           if (pickedTime!.hour > now.hour || (pickedTime!.hour == now.hour && pickedTime!.minute > now.minute)) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot select a future time")));
                               return;
                           }
                        }
                        setState(() {
                          dateController.text = "${pickedDate!.day.toString().padLeft(2, '0')}-${pickedDate!.month.toString().padLeft(2, '0')}-${pickedDate!.year} | ${pickedTime!.format(context)}";
                        });
                      }
                    }
                  }),
                  _buildTextField("Your Name", personNameController, readOnly: true, errorText: hasAttemptedSubmit && personNameController.text.trim().isEmpty ? "Required" : null),
                  _buildTextField("Mobile No. / Email ID", contactController, hintText: "e.g. 9876543210 or user@email.com", errorText: getContactError()),
                  
                  // Image Picker
                  const SizedBox(height: 8),
                  const Text("Upload Image (Optional)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (image != null) {
                        setState(() { selectedImagePath = image.path; });
                      }
                    },
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: selectedImagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(File(selectedImagePath!), fit: BoxFit.cover),
                                  Positioned(
                                    top: 8, right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() => selectedImagePath = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: softColor, shape: BoxShape.circle),
                                  child: Icon(Icons.cloud_upload_rounded, color: currentColor, size: 24),
                                ),
                                const SizedBox(height: 12),
                                const Text("Tap to select image", style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w700)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isUploading ? null : () async {
                        setState(() => hasAttemptedSubmit = true);
                        
                        bool validContact = RegExp(r'^\d{10}$').hasMatch(contactController.text.trim()) || RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$').hasMatch(contactController.text.trim());
                        
                        if (titleController.text.trim().isNotEmpty && descriptionController.text.trim().isNotEmpty && locationController.text.trim().isNotEmpty && dateController.text.trim().isNotEmpty && personNameController.text.trim().isNotEmpty && validContact) {
                          setState(() => isUploading = true);
                          try {
                            final isLost = _tabController.index == 0;
                            final userId = widget.ref.read(authNotifierProvider).value?.uid ?? "unknown";
                            
                            await widget.ref.read(lostAndFoundNotifierProvider.notifier).addReport(
                              title: titleController.text.trim(),
                              description: descriptionController.text.trim(),
                              location: locationController.text.trim(),
                              date: dateController.text.trim(),
                              personName: personNameController.text.trim(),
                              contactNumber: RegExp(r'^\d{10}$').hasMatch(contactController.text.trim()) ? '+91 ${contactController.text.trim()}' : '',
                              email: RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$').hasMatch(contactController.text.trim()) ? contactController.text.trim() : '',
                              isLost: isLost,
                              imagePath: selectedImagePath,
                              userId: userId,
                            );
                            
                            if (context.mounted) Navigator.of(context).pop(true);
                          } catch (e) {
                            setState(() => isUploading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error submitting report")));
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isUploading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              "Submit Report",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Manrope',
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumFab extends StatefulWidget {
  final VoidCallback onPressed;
  const _PremiumFab({required this.onPressed});

  @override
  State<_PremiumFab> createState() => _PremiumFabState();
}

class _PremiumFabState extends State<_PremiumFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFC62828)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F1A2C).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.15),
                blurRadius: 0,
                spreadRadius: 1,
                offset: const Offset(0, 1), // subtle inner highlight
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onPressed,
              splashColor: Colors.white.withValues(alpha: 0.25),
              highlightColor: Colors.white.withValues(alpha: 0.1),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: const Color(0xFFE5202B), size: 22),
                    SizedBox(width: 8),
                    Text(
                      "Report Item",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.2,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomDatePickerBottomSheet extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChanged;
  final Color themeColor;

  const _CustomDatePickerBottomSheet({
    super.key,
    required this.initialDate,
    required this.onDateChanged,
    required this.themeColor,
  });

  @override
  State<_CustomDatePickerBottomSheet> createState() => _CustomDatePickerBottomSheetState();
}

class _CustomDatePickerBottomSheetState extends State<_CustomDatePickerBottomSheet> {
  late int selectedDay;
  late int selectedMonth;
  late int selectedYear;

  final List<String> months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  late FixedExtentScrollController dayController;
  late FixedExtentScrollController monthController;
  late FixedExtentScrollController yearController;

  @override
  void initState() {
    super.initState();
    selectedDay = widget.initialDate.day;
    selectedMonth = widget.initialDate.month;
    selectedYear = widget.initialDate.year;

    dayController = FixedExtentScrollController(initialItem: selectedDay - 1);
    monthController = FixedExtentScrollController(initialItem: selectedMonth - 1);
    yearController = FixedExtentScrollController(initialItem: selectedYear - 2000);
  }
  
  @override
  void dispose() {
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    super.dispose();
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _updateDate() {
    int maxDays = _getDaysInMonth(selectedYear, selectedMonth);
    if (selectedDay > maxDays) {
      setState(() {
        selectedDay = maxDays;
      });
      dayController.jumpToItem(selectedDay - 1);
    }
    
    final now = DateTime.now();
    final currentSelected = DateTime(selectedYear, selectedMonth, selectedDay);
    final today = DateTime(now.year, now.month, now.day);
    if (currentSelected.isAfter(today)) {
       setState(() {
         selectedYear = now.year;
         selectedMonth = now.month;
         selectedDay = now.day;
       });
       yearController.animateToItem(selectedYear - 2000, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
       monthController.animateToItem(selectedMonth - 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
       dayController.animateToItem(selectedDay - 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    int maxDays = _getDaysInMonth(selectedYear, selectedMonth);
    final now = DateTime.now();

    return Container(
      height: 320,
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 60),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E6EE),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  'Next',
                  style: TextStyle(
                    color: widget.themeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                onPressed: () {
                  widget.onDateChanged(DateTime(selectedYear, selectedMonth, selectedDay));
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1A2C).withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ListWheelScrollView.useDelegate(
                        key: ValueKey(maxDays),
                        controller: dayController,
                        itemExtent: 54,
                        physics: const FixedExtentScrollPhysics(),
                        squeeze: 1.2,
                        diameterRatio: 1.5,
                        perspective: 0.003,
                        useMagnifier: true,
                        magnification: 1.2,
                        onSelectedItemChanged: (idx) {
                          selectedDay = idx + 1;
                          _updateDate();
                        },
                        childDelegate: ListWheelChildLoopingListDelegate(
                          children: List.generate(
                            maxDays,
                            (index) => Center(
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F1A2C), fontFamily: 'Manrope', decoration: TextDecoration.none),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: ListWheelScrollView.useDelegate(
                        controller: monthController,
                        itemExtent: 54,
                        physics: const FixedExtentScrollPhysics(),
                        squeeze: 1.2,
                        diameterRatio: 1.5,
                        perspective: 0.003,
                        useMagnifier: true,
                        magnification: 1.2,
                        onSelectedItemChanged: (idx) {
                          selectedMonth = idx + 1;
                          _updateDate();
                        },
                        childDelegate: ListWheelChildLoopingListDelegate(
                          children: List.generate(
                            12,
                            (index) => Center(
                              child: Text(
                                months[index],
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: widget.themeColor, fontFamily: 'Manrope', decoration: TextDecoration.none),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: ListWheelScrollView.useDelegate(
                        controller: yearController,
                        itemExtent: 54,
                        physics: const FixedExtentScrollPhysics(),
                        squeeze: 1.2,
                        diameterRatio: 1.5,
                        perspective: 0.003,
                        useMagnifier: true,
                        magnification: 1.2,
                        onSelectedItemChanged: (idx) {
                          selectedYear = 2000 + idx;
                          _updateDate();
                        },
                        childDelegate: ListWheelChildLoopingListDelegate(
                          children: List.generate(
                            now.year - 2000 + 1,
                            (index) => Center(
                              child: Text(
                                "${2000 + index}",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F1A2C), fontFamily: 'Manrope', decoration: TextDecoration.none),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _CustomTimePickerBottomSheet extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final Color themeColor;
  final DateTime? selectedDate;

  const _CustomTimePickerBottomSheet({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
    required this.themeColor,
    this.selectedDate,
  });

  @override
  State<_CustomTimePickerBottomSheet> createState() => _CustomTimePickerBottomSheetState();
}

class _CustomTimePickerBottomSheetState extends State<_CustomTimePickerBottomSheet> {
  late int selectedHour;
  late int selectedMinute;
  late int selectedAmPm; // 0 for AM, 1 for PM

  late FixedExtentScrollController hourController;
  late FixedExtentScrollController minuteController;
  late FixedExtentScrollController ampmController;

  @override
    void _updateTime() {
    if (widget.selectedDate == null) return;
    
    final now = DateTime.now();
    final isToday = widget.selectedDate!.year == now.year && widget.selectedDate!.month == now.month && widget.selectedDate!.day == now.day;
    
    if (isToday) {
      int hour24 = selectedAmPm == 0 ? (selectedHour == 12 ? 0 : selectedHour) : (selectedHour == 12 ? 12 : selectedHour + 12);
      bool isFuture = hour24 > now.hour || (hour24 == now.hour && selectedMinute > now.minute);
      
      if (isFuture) {
        setState(() {
          selectedHour = now.hour % 12;
          if (selectedHour == 0) selectedHour = 12;
          selectedMinute = now.minute;
          selectedAmPm = now.hour >= 12 ? 1 : 0;
        });
        hourController.animateToItem(selectedHour - 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        minuteController.animateToItem(selectedMinute, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        ampmController.animateToItem(selectedAmPm, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    selectedHour = widget.initialTime.hourOfPeriod;
    if (selectedHour == 0) selectedHour = 12; // 12 AM or 12 PM
    selectedMinute = widget.initialTime.minute;
    selectedAmPm = widget.initialTime.period == DayPeriod.am ? 0 : 1;

    hourController = FixedExtentScrollController(initialItem: selectedHour - 1);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);
    ampmController = FixedExtentScrollController(initialItem: selectedAmPm);
  }
  
  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    ampmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 60),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E6EE),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: widget.themeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                onPressed: () {
                  int finalHour = selectedHour;
                  if (selectedAmPm == 0 && finalHour == 12) finalHour = 0;
                  if (selectedAmPm == 1 && finalHour != 12) finalHour += 12;
                  widget.onTimeChanged(TimeOfDay(hour: finalHour, minute: selectedMinute));
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1A2C).withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ListWheelScrollView.useDelegate(
                        controller: hourController,
                        itemExtent: 54,
                        physics: const FixedExtentScrollPhysics(),
                        squeeze: 1.2,
                        diameterRatio: 1.5,
                        perspective: 0.003,
                        useMagnifier: true,
                        magnification: 1.2,
                        onSelectedItemChanged: (idx) {
                            selectedHour = idx + 1;
                            _updateTime();
                          },
                        childDelegate: ListWheelChildLoopingListDelegate(
                          children: List.generate(
                            12,
                            (index) => Center(
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F1A2C), fontFamily: 'Manrope', decoration: TextDecoration.none),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ListWheelScrollView.useDelegate(
                        controller: minuteController,
                        itemExtent: 54,
                        physics: const FixedExtentScrollPhysics(),
                        squeeze: 1.2,
                        diameterRatio: 1.5,
                        perspective: 0.003,
                        useMagnifier: true,
                        magnification: 1.2,
                        onSelectedItemChanged: (idx) {
                            selectedMinute = idx;
                            _updateTime();
                          },
                        childDelegate: ListWheelChildLoopingListDelegate(
                          children: List.generate(
                            60,
                            (index) => Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F1A2C), fontFamily: 'Manrope', decoration: TextDecoration.none),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ListWheelScrollView.useDelegate(
                        controller: ampmController,
                        itemExtent: 54,
                        physics: const FixedExtentScrollPhysics(),
                        squeeze: 1.2,
                        diameterRatio: 1.5,
                        perspective: 0.003,
                        useMagnifier: true,
                        magnification: 1.2,
                        onSelectedItemChanged: (idx) {
                            selectedAmPm = idx;
                            _updateTime();
                          },
                        childDelegate: ListWheelChildListDelegate(
                          children: [
                            Center(
                              child: Text(
                                "AM",
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: widget.themeColor, fontFamily: 'Manrope', decoration: TextDecoration.none),
                              ),
                            ),
                            Center(
                              child: Text(
                                "PM",
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: widget.themeColor, fontFamily: 'Manrope', decoration: TextDecoration.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
