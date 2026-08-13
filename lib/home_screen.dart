import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'widgets/premium_touch_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/timetable/presentation/providers/timetable_provider.dart';
import 'features/timetable/domain/timetable_entry.dart';
import 'package:intl/intl.dart';
import 'notifications_screen.dart';
import 'dart:ui';
import 'dart:math';
import 'features/timetable/presentation/screens/full_timetable_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'features/events/presentation/providers/events_provider.dart';
import 'features/events/data/events_service.dart';
import 'features/sgpa/presentation/providers/sgpa_provider.dart';
import 'lost_found_screen.dart';
import 'features/coding/presentation/leetcode_leaderboard_screen.dart';
import 'features/coding/presentation/codeforces_leaderboard_screen.dart';
import 'peer_to_peer_screen.dart';
import 'sgpa_calculator_screen.dart';
import 'sgpa_calc_coming_soon_screen.dart';
import 'profile_screen.dart';
import 'most_imp_screen.dart';
import 'notes_screen.dart';
import 'pyq_subjects_screen.dart';
import 'university_updates_screen.dart';
import 'package:flutter/services.dart';
import 'search/global_search_screen.dart';
import 'services/recent_files_service.dart';
import 'package:flutter/gestures.dart';
import 'services/notification_service.dart';
import 'features/notifications/presentation/providers/notifications_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

Route _createRoute(Widget page) {
  return CupertinoPageRoute(builder: (context) => page);
}
final clockProvider = StreamProvider.autoDispose<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 15), (_) => DateTime.now());
});

List<Map<String, String>> getTasksForDate(
  DateTime date,
  List<EventModel> allEvents,
) {
  final tasks = <Map<String, String>>[];

  final targetDate = DateTime(date.year, date.month, date.day);

  for (var event in allEvents) {
    final start = DateTime(
      event.startDate.year,
      event.startDate.month,
      event.startDate.day,
    );
    final end = DateTime(
      event.endDate.year,
      event.endDate.month,
      event.endDate.day,
    );

    if ((targetDate.isAtSameMomentAs(start) || targetDate.isAfter(start)) &&
        (targetDate.isAtSameMomentAs(end) || targetDate.isBefore(end))) {
      tasks.add({
        "title": event.title,
        "category": event.category,
        "time": event.time,
        "location": event.location,
        "totalMarks": event.totalMarks,
        "duration": event.duration,
        "classNo": event.classNo,
        "subject": event.subject,
        "isDynamic": "true",
      });
    }
  }

  // Filter tasks to only include Exams and Holidays (just in case)
  final filteredTasks = tasks
      .where((t) => t["category"] == "Exam" || t["category"] == "Holiday")
      .toList();

  filteredTasks.sort((a, b) {
    int getPriority(String cat) {
      if (cat == "Exam") return 0;
      if (cat == "Holiday") return 1;
      return 2;
    }

    return getPriority(
      a["category"] ?? "",
    ).compareTo(getPriority(b["category"] ?? ""));
  });

  return filteredTasks;
}

Color getCategoryColor(String category) {
  if (category == "Exam") return const Color(0xFFC62828);
  if (category == "Holiday") return const Color(0xFF10B981);
  return const Color(0xFF1E3A8A); // Custom Dark Blue
}

class NirmaHubApp extends StatelessWidget {
  const NirmaHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nirma Hub - Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF1F4F9), // Slate 50
        fontFamily: 'Manrope',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC62828)),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentNavIndex = 0;
  final ValueNotifier<int> _currentCarouselIndex = ValueNotifier<int>(0);
  final PageController _carouselController = PageController();

  DateTime _selectedDate = DateTime.now();
  DateTime _displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().checkAndRequestPermission(context);
    });
  }

  // Premium Design System Palette
  final Color baseNavy = const Color(0xFF0F172A); // Slate 900
  final Color primaryNavy = const Color(0xFF1E293B); // Slate 800
  final Color textGray = const Color(0xFF64748B); // Slate 500
  final Color borderGray = const Color(0xFFE2E8F0); // Slate 200
  final Color bgSurface = const Color(0xFFF1F4F9); // Slate 100
  final Color nirmaRed = const Color(0xFFC62828); // Brand Red

  @override
  Widget build(BuildContext context) {
    // Eagerly load SGPA and User Marks in the background on app launch for zero-latency
    ref.watch(sgpaProvider);
    ref.watch(userMarksProvider);

    final allEventsAsync = ref.watch(allEventsProvider);
    final allEvents = allEventsAsync.value ?? [];

    final semesterConfigAsync = ref.watch(semesterConfigProvider);
    final semesterConfig = semesterConfigAsync.value;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Press back again to exit',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Theme.of(context).colorScheme.surface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: baseNavy,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: bgSurface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleSpacing: 24,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: borderGray,
              height: 1,
            ), // Crisp hairline separator
          ),
          title: RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(
                  text: 'Nirma ',
                  style: TextStyle(color: baseNavy),
                ),
                TextSpan(
                  text: 'Hub',
                  style: TextStyle(color: nirmaRed),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: ref
                  .watch(notificationsProvider)
                  .when(
                    data: (notes) {
                      if (notes.isNotEmpty) {
                        return Badge(
                          label: Text(
                            notes.length.toString(),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: nirmaRed,
                          child: Icon(
                            CupertinoIcons.bell,
                            color: baseNavy,
                            size: 24,
                          ),
                        );
                      }
                      return Icon(
                        CupertinoIcons.bell,
                        color: baseNavy,
                        size: 24,
                      );
                    },
                    loading: () =>
                        Icon(CupertinoIcons.bell, color: baseNavy, size: 24),
                    error: (_, __) =>
                        Icon(CupertinoIcons.bell, color: baseNavy, size: 24),
                  ),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Builder(
                builder: (context) {
                  final authProfile = ref.watch(authNotifierProvider).value;
                  final imageUrl = authProfile?.profileImageUrl;
                  final hasImage = imageUrl != null && imageUrl.isNotEmpty;
                  final isLoading = authProfile == null || authProfile.fullName.isEmpty;
                  
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasImage 
                          ? Colors.transparent // Prevents the 0.5s black flash while NetworkImage loads
                          : (isLoading ? const Color(0xFFF1F4F9) : baseNavy),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.15), // Single thin black outline
                        width: 1.0, 
                      ),
                      image: hasImage 
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: hasImage
                        ? null
                        : isLoading
                            ? Icon(
                                CupertinoIcons.person_solid,
                                color: Theme.of(context).colorScheme.onSurfaceVariant, // Slate 400
                                size: 18,
                              )
                            : Text(
                                () {
                                  final name = authProfile.fullName;
                                  final parts = name.trim().split(RegExp(r'\s+'));
                                  if (parts.length > 1) {
                                    return parts[1][0].toUpperCase();
                                  }
                                  return parts[0][0].toUpperCase();
                                }(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.surface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  fontFamily: 'Inter',
                                ),
                              ),
                  );
                }
              ),
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            SizedBox(width: 8),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.02, 0.0), // Very fast micro-swipe
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _currentNavIndex == 0
              ? Container(
                  key: const ValueKey(0),
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 450, // Premium web/tablet bounds
                    child: RefreshIndicator(
                      color: nirmaRed,
                      onRefresh: () async {
                        ref.invalidate(allEventsProvider);
                        ref.invalidate(semesterConfigProvider);
                        await ref.read(allEventsProvider.future);
                        await ref.read(semesterConfigProvider.future);
                        await Future.delayed(const Duration(milliseconds: 300));
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 32.0,
                        ),
                        children: [
                          // --- Timetable & Academic Calendar Carousel ---
                          Column(
                            children: [
                              SizedBox(
                                height:
                                    400, // Compact explicit bounds for sleek sizing sizing
                                child: PageView(
                                  dragStartBehavior: DragStartBehavior.down,
                                  physics: const BouncingScrollPhysics(),
                                  controller: _carouselController,
                                  onPageChanged: (idx) {
                                    _currentCarouselIndex.value = idx;
                                  },
                                  children: [
                                    RepaintBoundary(
                                      child: _buildTimetableCard(),
                                    ),
                                    RepaintBoundary(
                                      child: _buildMiniCalendarCard(allEvents),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              ValueListenableBuilder<int>(
                                valueListenable: _currentCarouselIndex,
                                builder: (context, currentIndex, child) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildCarouselDot(0, currentIndex),
                                      SizedBox(width: 8),
                                      _buildCarouselDot(1, currentIndex),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 32),

                          // --- Core Tools Section ---
                          _buildSectionHeader('CORE TOOLS'),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCoreToolCard(
                                  'Timetable',
                                  CupertinoIcons.calendar,
                                  onTap: () => Navigator.push(
                                    context,
                                    _createRoute(const FullTimetableScreen()),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(child: SizedBox()),
                            ],
                          ),
                          SizedBox(height: 40),

                          // --- Campus Hub Section ---
                          _buildSectionHeader('CAMPUS HUB'),
                          SizedBox(height: 16),
                          _buildCampusHubItem(
                            title: 'Notes',
                            subtitle: 'Topper-Verified Notes',
                            icon: CupertinoIcons.doc_text,
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => const NotesScreen(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12),
                          _buildCampusHubItem(
                            title: 'PYQs',
                            subtitle: 'Previous Year Question Papers',
                            icon: CupertinoIcons.book,
                            color: const Color(0xFFC62828), // Nirma Red
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => const PyqSubjectsScreen(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12),
                          _buildCampusHubItem(
                            title: 'Most IMP',
                            subtitle: 'Important Topics & Questions',
                            icon: Icons.star_border,
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => const MostImpScreen(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 40),

                          // --- Semester Progress Bar ---
                          _buildSemesterProgressBar(semesterConfig),

                          SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                )
              : _currentNavIndex == 1
              ? SizedBox(key: const ValueKey(1), child: _buildStudySection())
              : SizedBox(key: const ValueKey(2), child: _buildStudentSection()),
        ),

        // --- Bottom Navigation ---
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: borderGray, width: 1)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            top: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _buildNavItem(
                1,
                Icons.menu_book_rounded,
                Icons.menu_book_outlined,
                'Study',
              ),
              _buildNavItem(
                2,
                Icons.school_rounded,
                Icons.school_outlined,
                'Student',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Premium UI Builders ---

  Widget _buildStudentSection() {
    return Container(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 450,
        child: RefreshIndicator(
          color: nirmaRed,
          onRefresh: () async {
            ref.invalidate(allEventsProvider);
            ref.invalidate(semesterConfigProvider);
            await ref.read(allEventsProvider.future);
            await ref.read(semesterConfigProvider.future);
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            children: [
              _buildSectionHeader('STUDENT SERVICES'),
              SizedBox(height: 16),
              _buildCampusHubItem(
                title: 'Lost & Found',
                subtitle: 'Report or find missing items',
                icon: Icons.search,
                color: nirmaRed,
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => LostAndFoundPage()),
                  );
                },
              ),
              SizedBox(height: 12),
              _buildCampusHubItem(
                title: 'Peer to Peer',
                subtitle: 'Buy or sell academic gear',
                icon: Icons.storefront,
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => MarketFeedScreen()),
                  );
                },
              ),
              SizedBox(height: 12),
              _buildCampusHubItem(
                title: 'LeetCode Rankings',
                subtitle: 'Campus LeetCode Leaderboard',
                icon: Icons.code,
                color: const Color(0xFFEAB308),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => LeetCodeLeaderboardScreen(),
                    ),
                  );
                },
              ),
              SizedBox(height: 12),
              _buildCampusHubItem(
                title: 'Codeforces Rankings',
                subtitle: 'Campus Codeforces Leaderboard',
                icon: Icons.bar_chart,
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => CodeforcesLeaderboardScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudySection() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Global Search Bar
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const GlobalSearchScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderGray.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.search, color: textGray, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Search Notes, PYQs, Topics...',
                    style: TextStyle(
                      color: textGray,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // University Updates Section
          _buildSectionHeader('UNIVERSITY ANNOUNCEMENTS'),
          SizedBox(height: 16),
          _buildCampusHubItem(
            title: 'New Updates',
            subtitle: 'Timetables, Curricular changes, & News',
            icon: CupertinoIcons.news_solid,
            isHighlight: true,
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => const UniversityUpdatesScreen(),
                ),
              );
            },
          ),
          SizedBox(height: 32),

          ValueListenableBuilder<List<RecentFile>>(
            valueListenable: RecentFilesService.recentFilesNotifier,
            builder: (context, recentFiles, _) {
              List<RecentFile> displayFiles = recentFiles;
              
              Widget listWidget;
              if (displayFiles.isEmpty) {
                listWidget = Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderGray.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        CupertinoIcons.folder_badge_plus,
                        size: 40,
                        color: borderGray,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "No recent files yet",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: baseNavy,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Start studying to see your recent files here",
                        style: TextStyle(fontSize: 12, color: textGray),
                      ),
                    ],
                  ),
                );
              } else {
                listWidget = SizedBox(
                  height: 170,
                  child: Stack(
                    children: [
                      ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: displayFiles.length,
                        itemBuilder: (context, index) {
                          final file = displayFiles[index];
                          
                          // Specific 5 colors requested for test: Red, Purple, Green, Yellow, Red
                          final themes = [
                      const Color(0xFFE5202B), // Red
                      const Color(0xFF8B5CF6), // Purple
                      const Color(0xFF10B981), // Green
                      const Color(0xFFF59E0B), // Yellow
                      const Color(0xFFE5202B), // Red
                    ];
                    final themeColor = themes[index % 5];
                    
                    String fileExtension = 'PDF';
                    if (!file.url.toLowerCase().endsWith('.pdf') && !file.title.toLowerCase().endsWith('.pdf')) {
                       fileExtension = 'FILE';
                    }

                    return Container(
                      width: 145,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(23),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(23),
                              splashColor: themeColor.withValues(alpha: 0.1),
                              highlightColor: themeColor.withValues(alpha: 0.05),
                              onTap: () {
                                if (file.url.toLowerCase().endsWith('.pdf') || file.title.toLowerCase().endsWith('.pdf')) {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      opaque: true,
                                      pageBuilder: (context, animation, secondaryAnimation) => PdfViewerScreen(
                                        pdfTitle: file.title,
                                        pdfUrl: file.url,
                                        pdfType: file.type,
                                      ),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return SlideTransition(
                                          position: animation.drive(Tween(begin: const Offset(0.0, 1.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                } else {
                                  launchUrl(Uri.parse(file.url), mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _CardWavePainter(color: themeColor),
                                    ),
                                  ),
                                  // Top Right Sparkle
                                Positioned(
                                  top: 14,
                                  right: 14,
                                  child: Icon(
                                    CupertinoIcons.sparkles,
                                    size: 16,
                                    color: themeColor,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top-left Pill Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: themeColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          fileExtension,
                                          style: TextStyle(
                                            color: themeColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'Manrope',
                                          ),
                                        ),
                                      ),
                                      
                                      Spacer(flex: 1),
                                      
                                      // Premium central flat icon
                                      Center(
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: themeColor.withValues(alpha: 0.1),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.description_rounded,
                                              color: themeColor,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      Spacer(flex: 2),
                                      
                                      // Lower side text
                                      Text(
                                        file.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Theme.of(context).colorScheme.onSurface,
                                          height: 1.2,
                                          fontFamily: 'Manrope',
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        file.type,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontFamily: 'Manrope',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      );
                    },
                  ),
                  if (displayFiles.length > 2)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 60,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                const Color(0xFFF1F4F9).withValues(alpha: 0.0),
                                const Color(0xFFF1F4F9).withValues(alpha: 0.7),
                                const Color(0xFFF1F4F9).withValues(alpha: 1.0),
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 0),
                              child: Icon(
                                Icons.keyboard_arrow_right_rounded,
                                color: textGray.withValues(alpha: 0.4),
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }
          
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent Files Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "RECENT FILES",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: textGray,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (displayFiles.length > 2)
                      // Empty placeholder just to keep structure but removed the swipe text from here
                      SizedBox.shrink(),
                  ],
                ),
                SizedBox(height: 12),
                listWidget,
              ],
            );
          },
        ),
          SizedBox(height: 32),
          Text(
            "STUDY MATERIALS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textGray,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 12),

          Column(
            children: [
              _buildCampusHubItem(
                title: 'Notes',
                subtitle: 'Topper-Verified Notes',
                icon: CupertinoIcons.book,
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const NotesScreen(),
                    ),
                  );
                },
              ),
              SizedBox(height: 12),
              _buildCampusHubItem(
                title: 'PYQs',
                subtitle: 'Previous Year Question Papers',
                icon: CupertinoIcons.doc_on_clipboard,
                color: const Color(0xFF10B981), // Emerald Green
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const PyqSubjectsScreen(),
                    ),
                  );
                },
              ),
              SizedBox(height: 12),
              _buildCampusHubItem(
                title: 'Most IMP',
                subtitle: 'Important Topics & Questions',
                icon: CupertinoIcons.flame,
                color: nirmaRed,
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const MostImpScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudyCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: _premiumCardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          splashColor: nirmaRed.withValues(alpha: 0.1),
          highlightColor: nirmaRed.withValues(alpha: 0.05),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 120), onTap);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: baseNavy,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunitySection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.person_3, size: 64, color: borderGray),
          SizedBox(height: 16),
          Text(
            'Community Section Coming Soon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textGray,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyGridCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: _premiumCardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {}, // To be linked to respective screens
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 36),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: baseNavy,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: textGray,
        letterSpacing: 1.5,
      ),
    );
  }

  BoxDecoration _premiumCardDecoration() {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderGray, width: 1.0),
      boxShadow: [
        BoxShadow(
          color: baseNavy.withValues(alpha: 0.02),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildTimetableCard() {
    final isTimetableLoading = ref.watch(timetableLoadingProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final currentMins = now.hour * 60 + now.minute;
    final currentDay = DateFormat('EEE').format(now).toUpperCase();

    final timetable = ref.watch(timetableProvider);
    final todaysLectures = timetable.where((t) => t.day == currentDay).toList();

    int maxEndMins = 0;
    if (todaysLectures.isNotEmpty) {
      maxEndMins = todaysLectures
          .map((t) => _timeToMinutes(t.endTime))
          .reduce(max);
    }

    bool isTomorrowActive = false;
    if (todaysLectures.isNotEmpty && currentMins >= maxEndMins + 30) {
      isTomorrowActive = true;
    } else if (!isTimetableLoading &&
        todaysLectures.isEmpty &&
        currentMins > 12 * 60) {
      isTomorrowActive = true;
    }

    DateTime targetDate = now;

    if (now.weekday == DateTime.saturday) {
      targetDate = now.add(const Duration(days: 2));
      isTomorrowActive = true;
    } else if (now.weekday == DateTime.sunday) {
      targetDate = now.add(const Duration(days: 1));
      isTomorrowActive = true;
    } else if (isTomorrowActive) {
      targetDate = now.add(const Duration(days: 1));
      if (targetDate.weekday == DateTime.saturday) {
        targetDate = targetDate.add(const Duration(days: 2));
      }
    }

    // Always explicitly show the Day name (e.g. "Monday's Timetable")
    String titleText;
    final tomorrow = now.add(const Duration(days: 1));
    if (targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day) {
      titleText = "Today's ";
    } else if (targetDate.year == tomorrow.year &&
        targetDate.month == tomorrow.month &&
        targetDate.day == tomorrow.day) {
      titleText = "Tomorrow's ";
    } else {
      titleText = "${DateFormat('EEEE').format(targetDate)}'s ";
    }
    String targetDay = DateFormat('EEE').format(targetDate).toUpperCase();

    final targetLectures = timetable.where((t) => t.day == targetDay).toList();
    targetLectures.sort(
      (a, b) =>
          _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)),
    );

    Set<String> morningDays = {};
    for (var lecture in timetable) {
      if (_timeToMinutes(lecture.startTime) < 700) {
        morningDays.add(lecture.day);
      }
    }
    bool isMorningShift = morningDays.length > 1;
    final mainStartTime = isMorningShift ? "07:45 AM" : "11:40 AM";
    final mainEndTime = isMorningShift ? "02:25 PM" : "06:20 PM";

    return Container(
      decoration: _premiumCardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    _createRoute(const FullTimetableScreen()),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      titleText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: nirmaRed,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    Text(
                      "Timetable",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: baseNavy,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
              PremiumTouchButton(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    _createRoute(const FullTimetableScreen()),
                  );
                },
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.list_bullet,
                        color: nirmaRed,
                        size: 12,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Full",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: nirmaRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: Stack(
              children: [
                (isTimetableLoading && targetLectures.isEmpty)
                    ? const _TimetableSkeleton()
                    : targetLectures.isEmpty
                    ? Center(
                        child: Text(
                          "No classes scheduled! 🎉",
                          style: TextStyle(
                            color: textGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        physics: const ClampingScrollPhysics(),
                        itemCount: targetLectures.length,
                        itemBuilder: (context, index) {
                          final lecture = targetLectures[index];

                          Widget freeLectureWidget = SizedBox.shrink();
                          Widget endFreeLectureWidget = SizedBox.shrink();

                          String getGapLabel(String startStr, String endStr) {
                            int s = _timeToMinutes(startStr);
                            int e = _timeToMinutes(endStr);

                            if (isMorningShift) {
                              // Lunch: 11:40 AM (700) to 12:35 PM (755)
                              if (s <= 700 && e >= 755) return "Lunch Break";
                            } else {
                              // Lunch: 01:30 PM (810) to 02:25 PM (865)
                              if (s <= 810 && e >= 865) return "Lunch Break";
                            }
                            return "Free Lecture";
                          }

                          if (index == 0) {
                            if (_timeToMinutes(lecture.startTime) >
                                _timeToMinutes(mainStartTime)) {
                              freeLectureWidget = Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _buildFreeLectureRow(
                                  mainStartTime,
                                  lecture.startTime,
                                  label: getGapLabel(
                                    mainStartTime,
                                    lecture.startTime,
                                  ),
                                ),
                              );
                            }
                          } else {
                            final prev = targetLectures[index - 1];
                            final gap =
                                _timeToMinutes(lecture.startTime) -
                                _timeToMinutes(prev.endTime);
                            if (gap > 15) {
                              freeLectureWidget = Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _buildFreeLectureRow(
                                  prev.endTime,
                                  lecture.startTime,
                                  label: getGapLabel(
                                    prev.endTime,
                                    lecture.startTime,
                                  ),
                                ),
                              );
                            }
                          }

                          if (index == targetLectures.length - 1) {
                            if (_timeToMinutes(lecture.endTime) <
                                _timeToMinutes(mainEndTime)) {
                              endFreeLectureWidget = Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _buildFreeLectureRow(
                                  lecture.endTime,
                                  mainEndTime,
                                  label: getGapLabel(
                                    lecture.endTime,
                                    mainEndTime,
                                  ),
                                ),
                              );
                            }
                          }

                          return Column(
                            children: [
                              freeLectureWidget,
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _buildTimetableRow(
                                  lecture.startTime,
                                  lecture.endTime,
                                  lecture.subject,
                                  lecture.professor,
                                  lecture.location,
                                  isTomorrowActive,
                                  now,
                                ),
                              ),
                              endFreeLectureWidget,
                            ],
                          );
                        },
                      ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: textGray.withValues(alpha: 0.4),
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeLectureRow(
    String startTime,
    String endTime, {
    String label = "Free Lecture",
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 85,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  startTime,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textGray.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 2,
            margin: const EdgeInsets.only(right: 16),
            color: borderGray.withValues(alpha: 0.5),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textGray.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _timeToMinutes(String timeStr) {
    if (timeStr.isEmpty) return 0;
    final parts = timeStr.split(' ');
    final hm = parts[0].split(':');
    int h = int.parse(hm[0]);
    int m = int.parse(hm[1]);
    if (parts.length > 1) {
      if (parts[1] == "PM" && h != 12) h += 12;
      if (parts[1] == "AM" && h == 12) h = 0;
    }
    return h * 60 + m;
  }

  Widget _buildTimetableRow(
    String time,
    String endTimeStr,
    String title,
    String prof,
    String location,
    bool isTomorrowActive,
    DateTime now,
  ) {
    // ACTIVE LIVE ENGINE - Reintegrated System DateTime
    final currentMins = now.hour * 60 + now.minute;
    final startMins = _timeToMinutes(time);
    final endMins = _timeToMinutes(endTimeStr); // Uses dynamic end time

    Color lineColor;
    Color timeColor;
    Color locationColor;
    IconData? stateIcon;
    Color? stateIconColor;

    if (isTomorrowActive) {
      lineColor = nirmaRed; // Red (Future)
      locationColor = nirmaRed;
      timeColor = textGray;
      stateIcon = null;
    } else if (currentMins >= endMins) {
      lineColor = const Color(0xFF10B981); // Green (Past)
      locationColor = const Color(0xFF10B981);
      timeColor = const Color(
        0xFF10B981,
      ); // Text explicitly converted identically mapped to Green
      stateIcon = CupertinoIcons
          .checkmark_seal_fill; // Identical green serrated tick badge
      stateIconColor = const Color(0xFF10B981);
    } else if (currentMins >= startMins && currentMins < endMins) {
      lineColor = const Color(0xFFF59E0B); // Yellow (Current)
      locationColor = const Color(0xFF10B981); // Green (Current Location)
      timeColor = const Color(0xFFF59E0B);
      stateIcon = Icons.radio_button_checked; // Double yellow round marker
      stateIconColor = const Color(0xFFF59E0B);
    } else {
      lineColor = nirmaRed; // Red (Future)
      locationColor = nirmaRed;
      timeColor = textGray;
      stateIcon = null;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 85,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: timeColor,
                  ),
                ),
                if (stateIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Icon(stateIcon, color: stateIconColor, size: 14),
                  ),
              ],
            ),
          ),
          Container(
            width: 2,
            margin: const EdgeInsets.only(right: 16),
            color: lineColor,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: baseNavy,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.person_solid,
                      size: 12,
                      color: textGray.withValues(alpha: 0.6),
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        prof,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textGray.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        "|",
                        style: TextStyle(
                          fontSize: 13,
                          color: textGray.withValues(alpha: 0.3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.location_solid,
                      size: 12,
                      color: locationColor.withValues(alpha: 0.8),
                    ),
                    SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: locationColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCalendarCard(List<EventModel> allEvents) {
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    DateTime displayDate = now;
    List<Map<String, dynamic>> displayEvents = getTasksForDate(now, allEvents);
    String scheduleTitle = "TODAY'S SCHEDULE";

    if (displayEvents.isEmpty) {
      for (int i = 1; i <= 30; i++) {
        final nextDate = now.add(Duration(days: i));
        final nextEvents = getTasksForDate(nextDate, allEvents);
        if (nextEvents.isNotEmpty) {
          displayDate = nextDate;
          displayEvents = nextEvents;
          scheduleTitle = i == 1 ? "TOMORROW'S SCHEDULE" : "UPCOMING SCHEDULE";
          break;
        }
      }
    }

    final String fullMonthStr = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ][displayDate.month - 1];
    final String weekdayStr = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ][displayDate.weekday - 1];

    final bool hasExamToday = displayEvents.any((e) => e["category"] == "Exam");
    final bool isToday =
        displayDate.year == now.year &&
        displayDate.month == now.month &&
        displayDate.day == now.day;

    return Container(
      decoration: _premiumCardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    _createRoute(const FullCalendarScreen()),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      isToday ? "Today's " : "Upcoming ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: nirmaRed,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    Text(
                      "Event",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: baseNavy,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
              PremiumTouchButton(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    _createRoute(const FullCalendarScreen()),
                  );
                },
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.calendar, color: nirmaRed, size: 12),
                      SizedBox(width: 6),
                      Text(
                        "Full",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: nirmaRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const FullCalendarScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: nirmaRed.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: nirmaRed.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: nirmaRed.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      "${displayDate.day}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: nirmaRed,
                        height: 1.0,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Manrope',
                            ),
                            children: [
                              TextSpan(
                                text: "$fullMonthStr, ",
                                style: TextStyle(color: nirmaRed),
                              ),
                              TextSpan(
                                text: weekdayStr,
                                style: TextStyle(color: baseNavy),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "${displayEvents.length} events scheduled",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasExamToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: nirmaRed,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        "Exam",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const FullCalendarScreen()),
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    scheduleTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: textGray,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: textGray,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                displayEvents.isEmpty
                    ? Center(
                        child: Text(
                          "No events scheduled! 🎉",
                          style: TextStyle(
                            color: textGray,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        physics: const ClampingScrollPhysics(),
                        itemCount: displayEvents.length,
                        itemBuilder: (ctx, i) {
                          final task = displayEvents[i];
                          return _buildEventRow(
                            task["title"]!,
                            task["category"] ?? "Event",
                            displayDate,
                            now,
                            time: task["time"],
                            location: task["location"],
                            totalMarks: task["totalMarks"] ?? "70 Marks",
                            duration: task["duration"] ?? "3 Hours",
                            classNo: task["classNo"] ?? "",
                            subject: task["subject"] ?? "",
                            isDynamic: task["isDynamic"] == "true",
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => const FullCalendarScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                if (displayEvents.isNotEmpty) ...[
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.7),
                              Colors.white,
                            ],
                            stops: [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: textGray.withValues(alpha: 0.4),
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventRow(
    String title,
    String category,
    DateTime date,
    DateTime now, {
    VoidCallback? onTap,
    String? time,
    String? location,
    String totalMarks = "70 Marks",
    String duration = "3 Hours",
    String classNo = "",
    String subject = "",
    bool isDynamic = false,
  }) {
    Color catColor = getCategoryColor(category);

    // LIVE EVENT COMPLETION ENGINE
    bool isCompleted = false;

    if (date.year < now.year ||
        (date.year == now.year && date.month < now.month) ||
        (date.year == now.year &&
            date.month == now.month &&
            date.day < now.day)) {
      isCompleted = true;
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day &&
        time != null &&
        time != "All Day") {
      final startMins = _timeToMinutes(time);
      final currentMins = now.hour * 60 + now.minute;
      if (currentMins >= startMins + 120) {
        isCompleted = true;
      }
    }

    final bool isCompletedExam = isCompleted && category == "Exam";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: isCompletedExam
          ? BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                width: 1.5,
              ),
            )
          : BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderGray.withValues(alpha: 0.5)),
            ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: isCompletedExam
              ? const Color(0xFF10B981).withValues(alpha: 0.1)
              : nirmaRed.withValues(alpha: 0.1),
          highlightColor: isCompletedExam
              ? const Color(0xFF10B981).withValues(alpha: 0.05)
              : nirmaRed.withValues(alpha: 0.05),
          onTap: category == "Exam"
              ? () => showExamDetailsBottomSheet(
                  context,
                  title,
                  time ?? "10:00 AM",
                  location ?? "Room B-203",
                  date,
                  totalMarks,
                  duration,
                  classNo,
                  subject,
                )
              : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Time Box
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCompletedExam
                        ? Colors.transparent
                        : catColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isCompletedExam
                      ? Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: const Color(0xFF10B981),
                          size: 24,
                        )
                      : Text(
                          time?.replaceFirst(" ", "\n") ?? "10:00\nAM",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: catColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            height: 1.1,
                          ),
                        ),
                ),
                SizedBox(width: 12),
                // Title and Location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: baseNavy,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.location_solid,
                            size: 10,
                            color: textGray,
                          ),
                          SizedBox(width: 4),
                          Text(
                            location ?? "No Location",
                            style: TextStyle(
                              color: textGray,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Category Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCompletedExam
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : catColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCompletedExam
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : catColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isCompletedExam
                          ? const Color(0xFF10B981)
                          : catColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(getCategoryColor("Exam"), 'Exam'),
        SizedBox(width: 16),
        _buildLegendItem(getCategoryColor("Holiday"), 'Holiday'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textGray,
          ),
        ),
      ],
    );
  }

  Widget _buildSemesterProgressBar(SemesterConfigModel? semesterConfig) {
    return RepaintBoundary(
      child: PremiumSemesterProgress(semesterConfig: semesterConfig),
    );
  }

  Widget _buildCoreToolCard(
    String label,
    IconData icon, {
    VoidCallback? onTap,
  }) {
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
            side: BorderSide(color: borderGray, width: 1.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    Future.delayed(const Duration(milliseconds: 120), onTap);
                  },
            splashColor: nirmaRed.withValues(alpha: 0.1),
            highlightColor: nirmaRed.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: nirmaRed.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: nirmaRed.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Icon(icon, color: nirmaRed, size: 22),
                  ),
                  SizedBox(height: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: baseNavy,
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

  Widget _buildCampusHubItem({
    required String title,
    required String subtitle,
    required IconData icon,
    bool isHighlight = false,
    Color? color,
    VoidCallback? onTap,
  }) {
    final Color itemColor = color ?? nirmaRed;
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
            side: BorderSide(color: borderGray, width: 1.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    Future.delayed(const Duration(milliseconds: 120), onTap);
                  },
            splashColor: itemColor.withValues(alpha: 0.1),
            highlightColor: itemColor.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isHighlight
                          ? itemColor
                          : itemColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: isHighlight
                          ? null
                          : Border.all(color: itemColor.withValues(alpha: 0.1)),
                    ),
                    child: Icon(
                      icon,
                      color: isHighlight ? Colors.white : itemColor,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: baseNavy,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: textGray.withValues(alpha: 0.5),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData defaultIcon,
    String label,
  ) {
    bool isSelected = _currentNavIndex == index;
    Color color = isSelected ? nirmaRed : textGray.withValues(alpha: 0.6);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _currentNavIndex = index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? activeIcon : defaultIcon,
                color: color,
                size: 26,
              ),
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: color,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselDot(int index, int currentIndex) {
    bool isSelected = currentIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isSelected ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isSelected ? baseNavy : borderGray,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// --- GLOBAL FULL CALENDAR ROUTE ---
class FullCalendarScreen extends ConsumerStatefulWidget {
  const FullCalendarScreen({super.key});

  @override
  ConsumerState<FullCalendarScreen> createState() => _FullCalendarScreenState();
}

class _FullCalendarScreenState extends ConsumerState<FullCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _displayedMonth;

  final Color baseNavy = const Color(0xFF0F172A);
  final Color textGray = const Color(0xFF64748B);
  final Color borderGray = const Color(0xFFE2E8F0);
  final Color bgSurface = const Color(0xFFF1F4F9);
  final Color nirmaRed = const Color(0xFFC62828);

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  BoxDecoration _premiumCardDecoration() {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderGray, width: 1.0),
      boxShadow: [
        BoxShadow(
          color: baseNavy.withValues(alpha: 0.02),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  int _timeToMinutes(String timeStr) {
    if (timeStr == "All Day" || timeStr.isEmpty) return 0;
    try {
      final parts = timeStr.split(' ');
      if (parts.length < 2) return 0;
      final timeParts = parts[0].split(':');
      if (timeParts.length < 2) return 0;
      int h = int.parse(timeParts[0]);
      int m = int.parse(timeParts[1]);
      if (parts[1].toUpperCase() == 'PM' && h != 12) h += 12;
      if (parts[1].toUpperCase() == 'AM' && h == 12) h = 0;
      return h * 60 + m;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildEventRow(
    String title,
    String category,
    DateTime date,
    DateTime now, {
    VoidCallback? onTap,
    String? time,
    String? location,
    String totalMarks = "70 Marks",
    String duration = "3 Hours",
    String classNo = "",
    String subject = "",
    bool isDynamic = false,
  }) {
    Color catColor = getCategoryColor(category);

    // LIVE EVENT COMPLETION ENGINE
    bool isCompleted = false;

    if (date.year < now.year ||
        (date.year == now.year && date.month < now.month) ||
        (date.year == now.year &&
            date.month == now.month &&
            date.day < now.day)) {
      isCompleted = true;
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day &&
        time != null &&
        time != "All Day") {
      final startMins = _timeToMinutes(time);
      final currentMins = now.hour * 60 + now.minute;
      if (currentMins >= startMins + 120) {
        isCompleted = true;
      }
    }

    final bool isCompletedExam = isCompleted && category == "Exam";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: isCompletedExam
          ? BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                width: 1.5,
              ),
            )
          : BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderGray.withValues(alpha: 0.5)),
            ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: isCompletedExam
              ? const Color(0xFF10B981).withValues(alpha: 0.1)
              : nirmaRed.withValues(alpha: 0.1),
          highlightColor: isCompletedExam
              ? const Color(0xFF10B981).withValues(alpha: 0.05)
              : nirmaRed.withValues(alpha: 0.05),
          onTap: category == "Exam"
              ? () => showExamDetailsBottomSheet(
                  context,
                  title,
                  time ?? "10:00 AM",
                  location ?? "Room B-203",
                  date,
                  totalMarks,
                  duration,
                  classNo,
                  subject,
                )
              : (isDynamic ? null : onTap),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Time Box
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCompletedExam
                        ? Colors.transparent
                        : catColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isCompletedExam
                      ? Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: const Color(0xFF10B981),
                          size: 24,
                        )
                      : Text(
                          time?.replaceFirst(" ", "\n") ?? "10:00\nAM",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: catColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            height: 1.1,
                          ),
                        ),
                ),
                SizedBox(width: 12),
                // Title and Location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: baseNavy,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.location_solid,
                            size: 10,
                            color: textGray,
                          ),
                          SizedBox(width: 4),
                          Text(
                            location ?? "No Location",
                            style: TextStyle(
                              color: textGray,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Category Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCompletedExam
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : catColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCompletedExam
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : catColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isCompletedExam
                          ? const Color(0xFF10B981)
                          : catColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textGray,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(
    List<EventModel> allEvents,
    SemesterConfigModel? semesterConfig,
  ) {
    int upcomingExams = 0;
    int upcomingHolidays = 0;

    // Exams and Holidays for the entire semester
    if (semesterConfig != null) {
      for (var t in allEvents) {
        if (t.startDate.isAfter(
              semesterConfig.startDate.subtract(const Duration(days: 1)),
            ) &&
            t.startDate.isBefore(
              semesterConfig.endDate.add(const Duration(days: 1)),
            )) {
          if (t.category == "Exam")
            upcomingExams++;
          else if (t.category == "Holiday")
            upcomingHolidays++;
        }
      }
    } else {
      for (var t in allEvents) {
        if (t.category == "Exam")
          upcomingExams++;
        else if (t.category == "Holiday")
          upcomingHolidays++;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildVerticalStatCard(
            "Exams",
            "$upcomingExams",
            CupertinoIcons.book_fill,
            nirmaRed,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildVerticalStatCard(
            "Holidays",
            "$upcomingHolidays",
            CupertinoIcons.sun_max_fill,
            const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray),
        boxShadow: [
          BoxShadow(
            color: baseNavy.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 12),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: baseNavy,
              height: 1.0,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textGray,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allEventsAsync = ref.watch(allEventsProvider);
    final allEvents = allEventsAsync.value ?? [];
    final semesterConfigAsync = ref.watch(semesterConfigProvider);
    final semesterConfig = semesterConfigAsync.value;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final firstDayOffset =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday - 1;
    final List<String> weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final String currentMonthString = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ][_displayedMonth.month - 1];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        title: Text(
          "Academic Calendar",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: baseNavy,
            fontSize: 18,
            fontFamily: 'Manrope',
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.0,
        elevation: 0,
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
                  child: Icon(
                    CupertinoIcons.arrow_left,
                    color: baseNavy,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderGray, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              decoration: _premiumCardDecoration(),
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: 12,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _displayedMonth = DateTime(
                                _displayedMonth.year,
                                _displayedMonth.month - 1,
                                1,
                              );
                            });
                          },
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.chevron_left,
                              color: textGray,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (BuildContext context) {
                              return _CustomDatePickerBottomSheet(
                                initialDate: _displayedMonth,
                                onDateChanged: (newDate) {
                                  setState(() {
                                    _displayedMonth = DateTime(
                                      newDate.year,
                                      newDate.month,
                                      1,
                                    );
                                    _selectedDate = newDate;
                                  });
                                },
                              );
                            },
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              currentMonthString,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: nirmaRed,
                              ),
                            ),
                            Text(
                              " ${_displayedMonth.year}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: baseNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _displayedMonth = DateTime(
                                _displayedMonth.year,
                                _displayedMonth.month + 1,
                                1,
                              );
                            });
                          },
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.chevron_right,
                              color: textGray,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: weekdays
                        .map(
                          (day) => Expanded(
                            child: Text(
                              day,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textGray,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 16),
                  Stack(
                    children: [
                      GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity! > 0) {
                            setState(() {
                              _displayedMonth = DateTime(
                                _displayedMonth.year,
                                _displayedMonth.month - 1,
                                1,
                              );
                            });
                          } else if (details.primaryVelocity! < 0) {
                            setState(() {
                              _displayedMonth = DateTime(
                                _displayedMonth.year,
                                _displayedMonth.month + 1,
                                1,
                              );
                            });
                          }
                        },
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 42,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                                childAspectRatio: 1.0,
                              ),
                          itemBuilder: (context, index) {
                            int day = index - firstDayOffset + 1;
                            if (day < 1 || day > daysInMonth)
                              return SizedBox.shrink();

                            bool isToday =
                                day == now.day &&
                                _displayedMonth.month == now.month &&
                                _displayedMonth.year == now.year;
                            bool isSelected =
                                day == _selectedDate.day &&
                                _displayedMonth.month == _selectedDate.month &&
                                _displayedMonth.year == _selectedDate.year;

                            DateTime currentGridDate = DateTime(
                              _displayedMonth.year,
                              _displayedMonth.month,
                              day,
                            );
                            final dayTasks = getTasksForDate(
                              currentGridDate,
                              allEvents,
                            );

                            bool hasExam = dayTasks.any(
                              (t) => t["category"] == "Exam",
                            );
                            bool hasHoliday = dayTasks.any(
                              (t) => t["category"] == "Holiday",
                            );

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = DateTime(
                                    _displayedMonth.year,
                                    _displayedMonth.month,
                                    day,
                                  );
                                });
                              },
                              child: Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? nirmaRed
                                        : (hasExam
                                              ? nirmaRed.withValues(alpha: 0.1)
                                              : (hasHoliday
                                                    ? const Color(
                                                        0xFF10B981,
                                                      ).withValues(alpha: 0.1)
                                                    : (isToday
                                                          ? borderGray
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                )
                                                          : Colors
                                                                .transparent))),
                                    borderRadius: BorderRadius.circular(12),
                                    border: (isToday && !isSelected)
                                        ? Border.all(
                                            color: borderGray,
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$day',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight:
                                                  (isSelected || isToday)
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: isSelected
                                                  ? Colors.white
                                                  : (hasExam
                                                        ? nirmaRed
                                                        : (hasHoliday
                                                              ? const Color(
                                                                  0xFF10B981,
                                                                )
                                                              : (isToday
                                                                    ? nirmaRed
                                                                    : ((index % 7 ==
                                                                              6)
                                                                          ? nirmaRed
                                                                          : baseNavy)))),
                                              height: 1.0,
                                            ),
                                          ),
                                          if (hasExam || hasHoliday)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  if (hasExam)
                                                    Container(
                                                      width: 4,
                                                      height: 4,
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 1,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? Colors.white
                                                            : nirmaRed,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  if (hasHoliday)
                                                    Container(
                                                      width: 4,
                                                      height: 4,
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 1,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF10B981,
                                                              ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: PremiumTouchButton(
                          onTap: () {
                            setState(() {
                              _displayedMonth = DateTime(
                                now.year,
                                now.month,
                                1,
                              );
                              _selectedDate = now;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: nirmaRed.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.arrow_counterclockwise,
                              size: 20,
                              color: nirmaRed,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: borderGray.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCalendarLegend(nirmaRed, 'Exam'),
                        SizedBox(width: 32),
                        _buildCalendarLegend(
                          const Color(0xFF10B981),
                          'Holiday',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // --- AGENDA SECTION ---
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: baseNavy,
                  fontFamily: 'Manrope',
                ),
                children: [
                  TextSpan(
                    text: "Exams & ",
                    style: TextStyle(color: nirmaRed),
                  ),
                  TextSpan(text: "Events"),
                ],
              ),
            ),
            SizedBox(height: 16),

            Builder(
              builder: (context) {
                final dayEvents = getTasksForDate(_selectedDate, allEvents);

                if (dayEvents.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: _premiumCardDecoration(),
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.calendar_badge_minus,
                          size: 48,
                          color: borderGray,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No events for this date.",
                          style: TextStyle(
                            color: textGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: dayEvents.length,
                  itemBuilder: (context, i) {
                    final task = dayEvents[i];
                    return _buildEventRow(
                      task["title"]!,
                      task["category"] ?? "Event",
                      _selectedDate,
                      now,
                      time: task["time"],
                      location: task["location"],
                      totalMarks: task["totalMarks"] ?? "70 Marks",
                      duration: task["duration"] ?? "3 Hours",
                      classNo: task["classNo"] ?? "",
                      subject: task["subject"] ?? "",
                      isDynamic: task["isDynamic"] == "true",
                    );
                  },
                );
              },
            ),

            SizedBox(height: 16),

            // --- STATS ROW ---
            _buildStatCards(allEvents, semesterConfig),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

void showExamDetailsBottomSheet(
  BuildContext context,
  String title,
  String time,
  String location,
  DateTime date,
  String totalMarks,
  String duration,
  String classNo,
  String subject,
) {
  final String shortMonthStr = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ][date.month - 1];
  final String weekdayStr = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ][date.weekday - 1];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.only(
          top: 10,
          left: 20,
          right: 20,
          bottom: 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer, // App background (bgSurface)
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5202B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.edit_document,
                    color: Color(0xFFE5202B),
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 16,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFFFF0F2), const Color(0xFFFFE6E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5202B).withValues(alpha: 0.1),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: -220,
                      right: -80,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFFE5202B,
                          ).withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -190,
                      right: 0,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFFE5202B,
                          ).withValues(alpha: 0.03),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFE5202B,
                                      ).withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Icon(
                                    CupertinoIcons.calendar,
                                    color: Color(0xFFE5202B),
                                    size: 18,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        weekdayStr,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        "${date.day} $shortMonthStr '${date.year.toString().substring(2)}",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFE5202B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: const Color(
                              0xFFE5202B,
                            ).withValues(alpha: 0.15),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFE5202B,
                                      ).withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Icon(
                                    CupertinoIcons.time,
                                    color: Color(0xFFE5202B),
                                    size: 18,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Time",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        time,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFE5202B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            _buildExamInfoRow(
              context,
              CupertinoIcons.book,
              Colors.deepPurple,
              "Subject",
              subject.isNotEmpty ? subject : title,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildExamInfoRow(
                    context,
                    Icons.assignment_turned_in_outlined,
                    Colors.orange,
                    "Total Marks",
                    totalMarks,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildExamInfoRow(
                    context,
                    Icons.hourglass_empty,
                    Colors.green,
                    "Duration",
                    duration,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildExamInfoRow(
              context,
              CupertinoIcons.building_2_fill,
              Colors.blue,
              "Class No.",
              classNo.isNotEmpty ? classNo : location,
            ),
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.deepPurpleAccent,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "All the best!",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "You've got this. Stay focused and do your best.",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.heart_solid,
                    color: Colors.deepPurpleAccent,
                    size: 20,
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      );
    },
  );
}

Widget _buildExamInfoRow(
  BuildContext context,
  IconData icon,
  Color color,
  String title,
  String subtitle,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6)),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CustomDatePickerBottomSheet extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChanged;

  const _CustomDatePickerBottomSheet({
    required this.initialDate,
    required this.onDateChanged,
  });

  @override
  State<_CustomDatePickerBottomSheet> createState() =>
      _CustomDatePickerBottomSheetState();
}

class _CustomDatePickerBottomSheetState
    extends State<_CustomDatePickerBottomSheet> {
  late int selectedDay;
  late int selectedMonth;
  late int selectedYear;

  final List<String> months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
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
    monthController = FixedExtentScrollController(
      initialItem: selectedMonth - 1,
    );
    yearController = FixedExtentScrollController(
      initialItem: selectedYear - 2026,
    );
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
  }

  @override
  Widget build(BuildContext context) {
    int maxDays = _getDaysInMonth(selectedYear, selectedMonth);

    return Container(
      height: 320,
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 60),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: const Color(0xFFC62828),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                onPressed: () {
                  widget.onDateChanged(
                    DateTime(selectedYear, selectedMonth, selectedDay),
                  );
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
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
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontFamily: 'Manrope',
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
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
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFC62828),
                                  fontFamily: 'Manrope',
                                  decoration: TextDecoration.none,
                                ),
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
                          selectedYear = 2026 + idx;
                          _updateDate();
                        },
                        childDelegate: ListWheelChildLoopingListDelegate(
                          children: List.generate(
                            2100 - 2026 + 1,
                            (index) => Center(
                              child: Text(
                                "${2026 + index}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontFamily: 'Manrope',
                                  decoration: TextDecoration.none,
                                ),
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
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

double _getWaveY(double x, double animationValue) {
  const waveLength = 120.0;
  const waveAmplitude = 3.5;
  return waveAmplitude *
      sin((x / waveLength * pi * 2) - (animationValue * pi * 2));
}

class PremiumSemesterProgress extends StatefulWidget {
  final SemesterConfigModel? semesterConfig;
  const PremiumSemesterProgress({super.key, this.semesterConfig});

  @override
  State<PremiumSemesterProgress> createState() =>
      _PremiumSemesterProgressState();
}

class _PremiumSemesterProgressState extends State<PremiumSemesterProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime startDate =
        widget.semesterConfig?.startDate ?? DateTime(now.year, 7, 6);
    final DateTime endDate =
        widget.semesterConfig?.endDate ?? DateTime(now.year, 12, 20);
    final String semesterName =
        widget.semesterConfig?.semesterName ?? "3rd Semester";

    double progress = 0.0;
    if (now.isAfter(endDate)) {
      progress = 1.0;
    } else if (now.isBefore(startDate)) {
      progress = 0.0;
    } else {
      final int totalDays = endDate.difference(startDate).inDays;
      final int passedDays = now.difference(startDate).inDays;
      progress = (passedDays / totalDays).clamp(0.0, 1.0);
    }

    // Pixel-perfect Premium Colors
    const Color trackColor = Color(0xFFF3F4F6);
    const Color textGray = Color(0xFF64748B);
    const Color baseNavy = Color(0xFF0F172A);

    Color currentColor = const Color(0xFFC62828); // Nirma Hub Red
    Color topGradientColor = const Color(0xFFE53935);

    // Change to green after 90%
    if (progress >= 0.9) {
      currentColor = const Color(0xFF10B981);
      topGradientColor = const Color(0xFF34D399);
    }

    Widget buildMotivationalText() {
      TextStyle baseStyle = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontFamily: 'Manrope',
      );
      if (progress >= 1.0) {
        return RichText(
          text: TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: "Semester Complete! "),
              TextSpan(text: "🎉", style: TextStyle(fontSize: 15)),
            ],
          ),
        );
      } else if (progress >= 0.9) {
        return RichText(
          text: TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: "Almost there! "),
              TextSpan(text: "🌟", style: TextStyle(fontSize: 15)),
            ],
          ),
        );
      } else if (progress >= 0.6) {
        return RichText(
          text: TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: "Just "),
              TextSpan(
                text: "${((1.0 - progress) * 100).toInt()}%",
                style: TextStyle(color: currentColor),
              ),
              TextSpan(text: " more to go! "),
              TextSpan(text: "💪", style: TextStyle(fontSize: 15)),
            ],
          ),
        );
      } else if (progress >= 0.5) {
        return RichText(
          text: TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: "Over halfway done! "),
              TextSpan(text: "🚀", style: TextStyle(fontSize: 15)),
            ],
          ),
        );
      } else if (progress >= 0.4) {
        return RichText(
          text: TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: "Almost halfway there! "),
              TextSpan(text: "✨", style: TextStyle(fontSize: 15)),
            ],
          ),
        );
      } else {
        return RichText(
          text: TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: "Fresh start! Great things ahead. "),
              TextSpan(text: "🌱", style: TextStyle(fontSize: 15)),
            ],
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 24, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: currentColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  progress >= 1.0
                      ? Icons.task_alt_rounded
                      : Icons.bar_chart_rounded,
                  color: currentColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Semester Progress",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: baseNavy,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      semesterName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: currentColor,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 44,
          ), // Removed extra double-spacing to pull the header down
          // PROGRESS TRACK AREA
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              const double barHeight = 32.0;
              final double barWidth = width;
              final double fillWidth = (barWidth * progress).clamp(
                0.0,
                barWidth,
              );

              return SizedBox(
                height: 48, // 32px track + 16px liquid overflow
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // EMPTY TRACK (Grey flat base)
                    Positioned(
                      left: 0,
                      bottom: 0,
                      width: barWidth,
                      height: barHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: trackColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ANIMATED LIQUID WAVE
                    Positioned(
                      left: 0,
                      bottom: 0,
                      width: fillWidth,
                      height: 48,
                      child: ClipRRect(
                        borderRadius: BorderRadius.horizontal(
                          left: const Radius.circular(16),
                          right: progress >= 0.98
                              ? const Radius.circular(16)
                              : Radius.zero,
                        ),
                        child: AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _LiquidWavePainter(
                                _waveController.value,
                                currentColor,
                                topGradientColor,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // CAP & SPEECH BUBBLE
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, _) {
                        final val = _waveController.value;
                        double waveY = _getWaveY(fillWidth, val);
                        double capTilt =
                            cos((fillWidth / 120.0 * pi * 2) - (val * pi * 2)) *
                            0.15;

                        double columnLeft =
                            fillWidth -
                            30; // Center 60px bubble exactly over the crest
                        Color bubbleBg = Color.lerp(
                          Colors.white,
                          currentColor,
                          0.12,
                        )!;

                        return Positioned.fill(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Speech Bubble
                              Positioned(
                                left: columnLeft,
                                top:
                                    -2 +
                                    waveY -
                                    34, // Moved a little down towards the cap
                                child: SizedBox(
                                  width: 60,
                                  height: 36,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Bubble
                                      Stack(
                                        alignment: Alignment.bottomCenter,
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: bubbleBg,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF0F172A,
                                                  ).withValues(alpha: 0.02),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              "${(progress * 100).toInt()}%",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                color: currentColor,
                                                fontFamily: 'Manrope',
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: -3,
                                            child: Transform.rotate(
                                              angle: pi / 4,
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                color: bubbleBg,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Sparkles
                                      if (progress < 1.0) ...[
                                        Positioned(
                                          left: -4,
                                          top: 4,
                                          child: Icon(
                                            Icons.auto_awesome,
                                            color: Color(0xFFFF9E9E),
                                            size: 10,
                                          ),
                                        ),
                                        Positioned(
                                          right: -4,
                                          top: 16,
                                          child: Icon(
                                            Icons.auto_awesome,
                                            color: Color(0xFFFF9E9E),
                                            size: 12,
                                          ),
                                        ),
                                      ] else ...[
                                        Positioned(
                                          left: -4,
                                          top: 4,
                                          child: Icon(
                                            Icons.auto_awesome,
                                            color: Color(0xFF6EE7B7),
                                            size: 10,
                                          ), // Emerald 300
                                        ),
                                        Positioned(
                                          right: -4,
                                          top: 16,
                                          child: Icon(
                                            Icons.auto_awesome,
                                            color: Color(0xFF6EE7B7),
                                            size: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              // Education Cap
                              Positioned(
                                left:
                                    columnLeft +
                                    16, // Center of 28px icon in a 60px column
                                top:
                                    -6 +
                                    waveY, // Moved slightly up for perfect floating feel
                                child: Transform.rotate(
                                  angle: capTilt,
                                  child: Icon(
                                    Icons.school_rounded,
                                    color: currentColor,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: 4), // Pulled dates closer to the bar
          // DATES ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM d').format(startDate),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: currentColor,
                  fontFamily: 'Manrope',
                ),
              ),
              Text(
                DateFormat('MMM d').format(endDate),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: progress >= 1.0 ? currentColor : textGray,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // BOTTOM TEXT
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: currentColor, size: 16),
              SizedBox(width: 8),
              Flexible(child: buildMotivationalText()),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiquidWavePainter extends CustomPainter {
  final double animationValue;
  final Color baseColor;
  final Color topGradientColor;

  _LiquidWavePainter(
    this.animationValue,
    this.baseColor,
    this.topGradientColor,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    path.moveTo(size.width, size.height);
    path.lineTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y = 16.0 + _getWaveY(x, animationValue);
      if (x == 0)
        path.lineTo(0, y);
      else
        path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topGradientColor, baseColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);

    // Gloss glass highlight on the liquid surface
    final highlightPath = Path();
    for (double x = 0; x <= size.width; x++) {
      final y = 16.0 + _getWaveY(x, animationValue);
      if (x == 0)
        highlightPath.moveTo(0, y);
      else
        highlightPath.lineTo(x, y);
    }

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 10));

    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _TimetableSkeleton extends StatefulWidget {
  const _TimetableSkeleton();

  @override
  State<_TimetableSkeleton> createState() => _TimetableSkeletonState();
}

class _TimetableSkeletonState extends State<_TimetableSkeleton>
    with SingleTickerProviderStateMixin {
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
            padding: const EdgeInsets.only(bottom: 24),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant, // borderGray
                    borderRadius: BorderRadius.circular(16),
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

class _BubblePainter extends CustomPainter {
  final Color color;
  _BubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
      
    // Top-left bubble
    paint.color = color.withValues(alpha: 0.07);
    canvas.drawCircle(const Offset(10, 10), 65, paint);
    
    // Bottom-right bubble
    paint.color = color.withValues(alpha: 0.05);
    canvas.drawCircle(Offset(size.width - 5, size.height - 5), 85, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class _CardWavePainter extends CustomPainter {
  final Color color;
  _CardWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // 3 overlapping waves
    final paint1 = Paint()
      ..color = color.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    final paint2 = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    final paint3 = Paint()
      ..color = color.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    // Back wave (peaks left)
    final path1 = Path();
    path1.moveTo(0, size.height * 0.65);
    path1.quadraticBezierTo(size.width * 0.25, size.height * 0.55, size.width * 0.5, size.height * 0.75);
    path1.quadraticBezierTo(size.width * 0.75, size.height * 0.9, size.width, size.height * 0.7);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Middle wave (peaks right)
    final path2 = Path();
    path2.moveTo(0, size.height * 0.75);
    path2.quadraticBezierTo(size.width * 0.3, size.height * 0.85, size.width * 0.6, size.height * 0.7);
    path2.quadraticBezierTo(size.width * 0.8, size.height * 0.6, size.width, size.height * 0.65);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);

    // Front wave (peaks middle)
    final path3 = Path();
    path3.moveTo(0, size.height * 0.85);
    path3.quadraticBezierTo(size.width * 0.4, size.height * 0.65, size.width, size.height * 0.8);
    path3.lineTo(size.width, size.height);
    path3.lineTo(0, size.height);
    path3.close();
    canvas.drawPath(path3, paint3);

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
