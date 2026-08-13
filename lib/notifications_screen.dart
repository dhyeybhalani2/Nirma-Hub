import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/notifications/presentation/providers/notifications_provider.dart';
import 'features/notifications/domain/app_notification.dart';
import 'widgets/premium_touch_button.dart';
import 'peer_to_peer_screen.dart';
import 'lost_found_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  // Premium Design System Palette from Home Page
  final Color baseNavy = const Color(0xFF0F172A); // Slate 900
  final Color textGray = const Color(0xFF64748B); // Slate 500
  final Color borderGray = const Color(0xFFE2E8F0); // Slate 200
  final Color bgSurface = const Color(0xFFF1F4F9); // Slate 100
  final Color nirmaRed = const Color(0xFFC62828); // Brand Red

  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    // Ensure SnackBars don't linger on the Home Screen when this screen is popped
    _scaffoldMessenger?.clearSnackBars();
    super.dispose();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else if (difference.inHours > 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours == 1) {
      return '1 hour ago';
    } else if (difference.inMinutes > 1) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inMinutes == 1) {
      return '1 min ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncNotifications = ref.watch(notificationsProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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
                  child: Icon(CupertinoIcons.arrow_left, color: baseNavy, size: 18),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: baseNavy,
            letterSpacing: -0.5,
            fontFamily: 'Manrope',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderGray, width: 1)),
            ),
          ),
        ),
        actions: [
          asyncNotifications.when(
            data: (notes) {
              if (notes.isNotEmpty) {
                return IconButton(
                  icon: Icon(CupertinoIcons.trash, color: nirmaRed),
                  onPressed: () async {
                    await ref.read(notificationsProvider.notifier).clearAll();
                    setState(() {
                      _listKey = GlobalKey<AnimatedListState>();
                    });
                    ScaffoldMessenger.of(context).clearSnackBars();
                  },
                );
              }
              return SizedBox.shrink();
            },
            loading: () => SizedBox.shrink(),
            error: (_, __) => SizedBox.shrink(),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
        color: nirmaRed,
        child: asyncNotifications.when(
          loading: () => const _NotificationsSkeleton(),
          error: (err, stack) => _buildErrorState(err.toString()),
          data: (notifications) {
            if (notifications.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: _buildEmptyState(),
                ),
              );
            }

            return AnimatedList(
              key: _listKey,
              initialItemCount: notifications.length,
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 8.0),
              itemBuilder: (context, index, animation) {
                final note = notifications[index];
                return SizeTransition(
                  sizeFactor: animation,
                  child: SlideTransition(
                    position: animation.drive(Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    )),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Dismissible(
                        key: Key(note.id),
                        direction: DismissDirection.startToEnd,
                        onDismissed: (direction) {
                          final dismissedNote = note;
                          final dismissedIndex = index;
                          
                          // Animate removal: Slide down and shrink
                          _listKey.currentState?.removeItem(
                            dismissedIndex,
                            (context, animation) => SizeTransition(
                              sizeFactor: animation,
                              child: SlideTransition(
                                position: animation.drive(Tween<Offset>(
                                  begin: const Offset(0, 1), // Slide down on exit
                                  end: Offset.zero,
                                )),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: _buildNotificationCard(dismissedNote),
                                ),
                              ),
                            ),
                            duration: const Duration(milliseconds: 300),
                          );

                          // Smoothly hide any existing SnackBar before showing a new one
                          scaffoldMessenger.hideCurrentSnackBar();
                          
                          final controller = scaffoldMessenger.showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 4),
                              content: Text('Notification dismissed', style: TextStyle(fontWeight: FontWeight.w600)),
                              backgroundColor: const Color(0xFF0F172A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              action: SnackBarAction(
                                label: 'Undo',
                                textColor: const Color(0xFFC62828),
                                onPressed: () {
                                  scaffoldMessenger.hideCurrentSnackBar();
                                  
                                  ref.read(notificationsProvider.notifier).restoreNotification(dismissedNote, dismissedIndex).then((_) {
                                    _listKey.currentState?.insertItem(
                                      dismissedIndex,
                                      duration: const Duration(milliseconds: 300),
                                    );
                                  });
                                },
                              ),
                            ),
                          );

                          // Forcefully close the snackbar after 4 seconds to bypass OS accessibility overrides
                          Future.delayed(const Duration(seconds: 4), () {
                            try {
                              controller.close();
                            } catch (e) {
                              // Ignore if already closed
                            }
                          });

                          // Then remove from local storage state
                          ref.read(notificationsProvider.notifier).dismissNotification(note.id);
                        },
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(CupertinoIcons.trash, color: Color(0xFFEF4444), size: 28),
                        ),
                        child: _buildNotificationCard(note),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: bgSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(CupertinoIcons.bell_slash, size: 48, color: textGray.withValues(alpha: 0.5)),
          ),
          SizedBox(height: 24),
          Text(
            "No Notifications Yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: baseNavy,
              fontFamily: 'Manrope',
            ),
          ),
          SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textGray,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: nirmaRed),
          SizedBox(height: 16),
          Text(
            "Failed to load notifications",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: baseNavy,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textGray,
              ),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(notificationsProvider.notifier).refresh(),
            style: ElevatedButton.styleFrom(
              backgroundColor: nirmaRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Try Again"),
          )
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification note) {
    IconData iconData;
    Color iconColor = nirmaRed;
    Color iconBgColor = nirmaRed.withValues(alpha: 0.05);

    switch (note.type) {
      case 'app':
        iconData = CupertinoIcons.app;
        break;
      case 'lost_found':
        iconData = CupertinoIcons.search;
        break;
      case 'peer_to_peer':
        iconData = CupertinoIcons.person_2;
        break;
      case 'notes':
        iconData = CupertinoIcons.doc_text;
        break;
      case 'event':
        iconData = CupertinoIcons.ticket;
        break;
      case 'library':
        iconData = CupertinoIcons.book;
        break;
      case 'other':
      default:
        iconData = CupertinoIcons.bell;
        break;
    }

    return PremiumTouchButton(
      onTap: () {
        final titleLower = note.title.toLowerCase();
        final msgLower = note.message.toLowerCase();
        if (note.type == 'peer_to_peer' || titleLower.contains('peer to peer') || titleLower.contains('peer-to-peer') || msgLower.contains('peer to peer')) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketFeedScreen()));
        } else if (note.type == 'lost_found' || titleLower.contains('lost') || titleLower.contains('found') || msgLower.contains('lost and found')) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LostAndFoundPage()));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: note.isRead ? borderGray : nirmaRed.withValues(alpha: 0.3),
            width: note.isRead ? 1.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: baseNavy.withValues(alpha: note.isRead ? 0.02 : 0.08),
              blurRadius: note.isRead ? 8 : 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: nirmaRed.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                note.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: baseNavy,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              _formatTimeAgo(note.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textGray,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(right: 28.0),
                          child: Text(
                            note.message,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textGray,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      child: Align(
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.keyboard_double_arrow_right, 
                          color: baseNavy, 
                          size: 20,
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

class _NotificationsSkeleton extends StatefulWidget {
  const _NotificationsSkeleton();

  @override
  State<_NotificationsSkeleton> createState() => _NotificationsSkeletonState();
}

class _NotificationsSkeletonState extends State<_NotificationsSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.4 + (_controller.value * 0.6),
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 8.0),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
