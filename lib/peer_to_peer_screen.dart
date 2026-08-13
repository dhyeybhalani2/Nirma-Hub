import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ai/widgets/skeleton_loaders.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/utils/image_compressor.dart';
import 'widgets/premium_touch_button.dart';
import 'features/peer_to_peer/domain/peer_to_peer_item.dart';
import 'features/peer_to_peer/presentation/providers/peer_to_peer_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/moderation/presentation/providers/moderation_provider.dart';

class MarketFeedScreen extends ConsumerStatefulWidget {
  const MarketFeedScreen({super.key});

  @override
  ConsumerState<MarketFeedScreen> createState() => _MarketFeedScreenState();
}

class _MarketFeedScreenState extends ConsumerState<MarketFeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = "";
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Removed addListener that caused lag
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<PeerToPeerItem> _getFilteredItems(List<PeerToPeerItem> items, int tabIndex) {
    final currentUserId = ref.watch(authNotifierProvider).value?.id;
    final query = _searchQuery.toLowerCase().trim();
    return items.where((item) {
      final titleLower = item.title.toLowerCase();
      final matchesSearch = query.isEmpty ||
                            titleLower.startsWith(query) ||
                            titleLower.contains(' $query');
      bool matchesTab;
      if (tabIndex == 0) {
        matchesTab = !item.isSold;
      } else if (tabIndex == 1) {
        matchesTab = item.userId == currentUserId;
      } else {
        matchesTab = item.isSold;
      }
      return matchesSearch && matchesTab;
    }).toList();
  }

  void _showReportDialog(PeerToPeerItem item) {
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
                        itemType: 'peer_to_peer',
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
                    ref.read(peerToPeerItemsProvider.notifier).filterBlockedUserLocally(userId);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
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
                color: const Color(0xFFF1F5F9), // Flat grey background
                borderRadius: BorderRadius.circular(24), // Pill shape
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                cursorColor: const Color(0xFFC62828),
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                  border: InputBorder.none,
                  prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF94A3B8), size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                    icon: const Icon(CupertinoIcons.clear_circled_solid, color: Color(0xFF94A3B8), size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ) : null,
                ),
              ),
            )
          : const Text(
              'Peer to Peer',
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
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => setState(() => _isSearching = true),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(CupertinoIcons.search, color: Color(0xFF0F172A), size: 22),
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
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
                Tab(text: 'AVAILABLE'),
                Tab(text: 'MY LISTINGS'),
                Tab(text: 'SUCCESSFUL'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(0), // Available
          _buildTabContent(1), // My Listings
          _buildTabContent(2), // Successful
        ],
      ),
      floatingActionButton: _tabController.index != 2 
          ? FloatingActionButton.extended(
              onPressed: () => _showSellItemDialog(context),
              backgroundColor: const Color(0xFF0F172A),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Sell Item",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Manrope',
                ),
              ),
              elevation: 4,
            ) 
          : null,
    );
  }

  Widget _buildTabContent(int tabIndex) {
    final asyncItems = ref.watch(peerToPeerItemsProvider);
    
    return asyncItems.when(
      loading: () => const CustomScrollView(slivers: [P2PSkeleton()]),
      error: (err, stack) => Center(child: Text("Error loading items: $err", style: const TextStyle(color: Colors.red))),
      data: (items) {
        final filteredItems = _getFilteredItems(items, tabIndex);
        
        if (filteredItems.isEmpty) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.storefront_outlined, size: 48, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No items found.",
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            return ref.refresh(peerToPeerItemsProvider.future);
          },
          color: const Color(0xFFC62828),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 100),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _buildItemCard(filteredItems[index]),
              );
            },
          ),
        );
      },
    );
  }


  Widget _buildItemCard(PeerToPeerItem item) {
    return PremiumTouchButton(
      onTap: item.isSold 
        ? null 
        : () {
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
                          color: const Color(0xFFF1F5F9),
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
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.broken_image, color: Color(0xFF94A3B8)),
                        ),
                      ),
                ),
                if (item.isSold)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
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
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₹${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC62828),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.sellerName,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        item.createdAt.toString().substring(0, 10),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
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

  void _showItemDetails(BuildContext context, PeerToPeerItem item) {
    final currentUserId = ref.read(authNotifierProvider).value?.id;
    final isMyItem = item.userId == currentUserId;
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
                            color: const Color(0xFFF1F5F9),
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
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Color(0xFF94A3B8), size: 64),
                            ),
                          ),
                        ),
                    if (!isMyItem)
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
                              _showReportDialog(item);
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "₹" + item.price.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC62828),
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
                                      const Text(
                                        "Owner Name",
                                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.sellerName,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (!item.isSold) ...[
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
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled, size: 22, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Posted on: " + item.createdAt.toString().substring(0, 10),
                              style: const TextStyle(fontSize: 16, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      if (!item.isSold && isMyItem) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  ref.read(peerToPeerItemsProvider.notifier).markAsSold(item.id);
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text("Mark as Sold", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  ref.read(peerToPeerItemsProvider.notifier).deleteItem(item.id);
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEF2F2),
                                  foregroundColor: const Color(0xFFC62828),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ],
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

  void _showSellItemDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SellItemBottomSheet(ref: ref),
    );
  }
}

class _SellItemBottomSheet extends StatefulWidget {
  final dynamic ref;
  const _SellItemBottomSheet({required this.ref});

  @override
  State<_SellItemBottomSheet> createState() => _SellItemBottomSheetState();
}

class _SellItemBottomSheetState extends State<_SellItemBottomSheet> {
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descController = TextEditingController();
  late final TextEditingController nameController;
  final contactController = TextEditingController();
  
  String? selectedImagePath;
  bool hasAttemptedSubmit = false;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = widget.ref.read(authNotifierProvider).value;
    nameController = TextEditingController(text: user?.fullName ?? '');
  }

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    descController.dispose();
    nameController.dispose();
    contactController.dispose();
    super.dispose();
  }

  Color get currentColor => const Color(0xFFC62828);
  Color get softColor => const Color(0xFFC62828).withOpacity(0.1);

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, String? hintText, bool readOnly = false, VoidCallback? onTap, String? errorText, TextInputType? keyboardType, int? maxLength}) {
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
    
    return Container(
      margin: const EdgeInsets.only(top: kToolbarHeight),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
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
                    Icons.storefront_rounded,
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
                        "Sell an Item",
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
                    color: const Color(0xFFE2E6EE).withOpacity(0.5),
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
          
          // Scrollable Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: bottomInset + 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField("Item Title", titleController, hintText: "E.g., ED Set/Coat, Calculus Textbook", errorText: hasAttemptedSubmit && titleController.text.trim().isEmpty ? "Required" : null),
                  _buildTextField("Price (₹)", priceController, hintText: "E.g., 5000", keyboardType: TextInputType.number, errorText: hasAttemptedSubmit ? (priceController.text.trim().isEmpty ? "Required" : (double.tryParse(priceController.text.trim()) == null ? "Enter a valid number" : null)) : null),
                  _buildTextField("Description", descController, hintText: "Provide details about condition, usage, etc.", maxLines: 4, errorText: hasAttemptedSubmit && descController.text.trim().isEmpty ? "Required" : null),
                  _buildTextField("Your Name", nameController, readOnly: true, hintText: "What should buyers call you?", errorText: hasAttemptedSubmit && nameController.text.trim().isEmpty ? "Required" : null),
                  _buildTextField("Contact Info", contactController, hintText: "10-digit mobile or email", keyboardType: TextInputType.emailAddress, errorText: hasAttemptedSubmit ? (contactController.text.trim().isEmpty ? "Required" : (!(RegExp(r'^\d{10}$').hasMatch(contactController.text.trim()) || RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(contactController.text.trim())) ? "Invalid contact format" : null)) : null),
                  
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, top: 4),
                    child: Text(
                      "Upload Image (Required)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Manrope',
                        color: (hasAttemptedSubmit && selectedImagePath == null) ? const Color(0xFFC62828) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      try {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 30);
                        if (image != null) {
                          setState(() {
                            selectedImagePath = image.path;
                          });
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to pick image: $e")),
                        );
                      }
                    },
                    child: Container(
                      height: 120,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (hasAttemptedSubmit && selectedImagePath == null) ? Colors.red : const Color(0xFFE2E8F0), 
                          style: BorderStyle.solid
                        ),
                      ),
                      child: selectedImagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(File(selectedImagePath!), fit: BoxFit.cover, width: double.infinity),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 36, color: const Color(0xFF94A3B8)),
                                const SizedBox(height: 8),
                                const Text("Tap to upload image", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isUploading ? null : () async {
                        setState(() {
                          hasAttemptedSubmit = true;
                        });
                        
                        bool isContactValid = RegExp(r'^\d{10}$').hasMatch(contactController.text.trim()) || RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(contactController.text.trim());
                        if (titleController.text.trim().isNotEmpty && 
                            priceController.text.trim().isNotEmpty && double.tryParse(priceController.text.trim()) != null &&
                            descController.text.trim().isNotEmpty &&
                            nameController.text.trim().isNotEmpty &&
                            contactController.text.trim().isNotEmpty && isContactValid &&
                            selectedImagePath != null) {
                          
                          setState(() => isUploading = true);
                          
                          String? finalImagePath = selectedImagePath;
                          if (finalImagePath != null) {
                            finalImagePath = await ImageCompressor.compressImage(finalImagePath);
                          }
                          
                          widget.ref.read(peerToPeerItemsProvider.notifier).addItem(
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            price: double.parse(priceController.text.trim()),
                            condition: 'Used',
                            category: 'General',
                            imagePath: finalImagePath!,
                            contactNumber: RegExp(r'^\d{10}$').hasMatch(contactController.text.trim()) ? '+91 ' : contactController.text.trim(),
                            sellerName: nameController.text.trim(),
                          ).then((_) {
                            Navigator.pop(context);
                          }).catchError((e) {
                            setState(() => isUploading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: $e", style: const TextStyle(color: Colors.white)),
                                backgroundColor: const Color(0xFFC62828),
                              ),
                            );
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please fill out all required fields.", style: TextStyle(color: Colors.white)),
                              backgroundColor: Color(0xFFC62828),
                            ),
                          );
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
                              "Submit",
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
