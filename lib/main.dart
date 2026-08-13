import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart'; 
import 'features/auth/presentation/providers/auth_provider.dart';
import 'home_screen.dart';
import 'services/notification_service.dart';
import 'services/recent_files_service.dart';
import 'services/update_service.dart';
import 'services/analytics_service.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'peer_to_peer_screen.dart';
import 'lost_found_screen.dart';

late SharedPreferences sharedPrefs;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Parallelize all heavy initialization tasks to drastically cut launch time
  await Future.wait([
    SharedPreferences.getInstance().then((prefs) => sharedPrefs = prefs),
    NotificationService().init(),
    RecentFilesService.init(),
    Firebase.initializeApp(),
    Supabase.initialize(
      url: 'https://gqhuomepejnexzrfrghe.supabase.co', // WE STILL NEED THIS!
      anonKey: 'sb_publishable_AlWiUxEDlxKhgrZ5CT6TaA_y41quKQB',
    ),
  ]);

  // Non-blocking Firebase permission and subscription tasks (Fire-and-forget)
  void setupFirebaseMessaging() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await FirebaseMessaging.instance.subscribeToTopic('all_users');
    } catch (e) {
      print("Firebase Messaging Error: $e");
    }
  }
  setupFirebaseMessaging();

  NotificationService().listenForAppNotifications();

  runApp(const ProviderScope(child: NirmaHubApp()));
}

class NirmaHubApp extends StatefulWidget {
  const NirmaHubApp({super.key});

  @override
  State<NirmaHubApp> createState() => _NirmaHubAppState();
}

class _NirmaHubAppState extends State<NirmaHubApp> {
  @override
  void initState() {
    super.initState();
    _setupPushNotificationRouting();
  }

  void _setupPushNotificationRouting() async {
    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        NotificationService().flutterLocalNotificationsPlugin.show(
          id: message.notification.hashCode,
          title: message.notification!.title,
          body: message.notification!.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // Handle when app is in background and user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handlePushNotificationRoute);

    // Handle when app is terminated and user taps notification
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Delay slightly to ensure Navigator is mounted
      Future.delayed(const Duration(milliseconds: 500), () {
        _handlePushNotificationRoute(initialMessage);
      });
    }
  }

  void _handlePushNotificationRoute(RemoteMessage message) {
    final type = (message.data['type'] as String?)?.toLowerCase() ?? '';
    final title = (message.notification?.title ?? '').toLowerCase();
    final body = (message.notification?.body ?? '').toLowerCase();
    
    if (type == 'peer_to_peer' || title.contains('peer') || title.contains('p2p') || title.contains('market') || 
        body.contains('peer') || body.contains('p2p') || body.contains('market')) {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const MarketFeedScreen()));
    } else if (type == 'lost_found' || title.contains('lost') || title.contains('found') || body.contains('lost') || body.contains('found')) {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const LostAndFoundPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Nirma Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF1F4F9), // Slate 100
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC62828), // Nirma Red Focus
          primary: const Color(0xFF1A2B48), // Navy
          surface: Colors.white,
          surfaceTint: Colors.transparent,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFF8FAFC),
          surfaceContainer: const Color(0xFFF1F4F9),
          surfaceContainerHigh: const Color(0xFFE2E8F0),
          surfaceContainerHighest: const Color(0xFFCBD5E1),
          outline: const Color(0xFFCBD5E1),
          outlineVariant: const Color(0xFFE2E8F0),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: child!,
        );
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showSuccess = false;
  Session? _cachedSession;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates(context);
      AnalyticsService.logAppOpen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;
        final event = snapshot.hasData ? snapshot.data!.event : null;

        // Trigger success animation if we just logged in
        if (session != null && _cachedSession == null && event == AuthChangeEvent.signedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_showSuccess) {
              setState(() {
                _showSuccess = true;
                _cachedSession = session;
              });
              HapticFeedback.lightImpact();
              AudioPlayer().play(AssetSource('sounds/tick.wav'));
              // Delay navigation to show the green tick in the small box
              Future.delayed(const Duration(milliseconds: 1300), () {
                if (mounted) {
                  setState(() {
                    _showSuccess = false;
                  });
                }
              });
            }
          });
        } else if (session != null && !_showSuccess) {
          _cachedSession = session;
        } else if (session == null) {
          _cachedSession = null;
        }

        if (_showSuccess) {
          return const UnifiedAuthPage(isSuccessMode: true);
        }

        if (_cachedSession != null) {
          return const HomePage();
        }

        return const UnifiedAuthPage();
      },
    );
  }
}



class UnifiedAuthPage extends ConsumerStatefulWidget {
  final bool isSuccessMode;
  const UnifiedAuthPage({super.key, this.isSuccessMode = false});

  @override
  ConsumerState<UnifiedAuthPage> createState() => _UnifiedAuthPageState();
}

class _UnifiedAuthPageState extends ConsumerState<UnifiedAuthPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoginAction = true;
  bool _buttonPressed = false;
  final ScrollController _scrollController = ScrollController();
  
  late final AnimationController _domainShakeController;
  late final Animation<double> _domainShakeAnimation;

  // Text Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rollController = TextEditingController();
  final TextEditingController _divController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();

  // Dynamic Selections
  late List<String> _gradYears;
  String? _selectedGradYear;
  String _selectedYear = '1st';
  String? _selectedBranch;

  final List<String> _customBranches = [
    'Computer Science Engineering',
    'AI & ML',
    'Electronics and Communication Engineering',
    'Electrical Engineering',
    'Electronics and Instrumentation Engineering',
    'Electronics Engineering (VLSI Design and Semiconductor Technology)',
    'Mechanical Engineering',
    'Chemical Engineering',
    'Civil Engineering',
  ];

  final Map<String, IconData> _branchIcons = {
    'Computer Science Engineering': Icons.computer_rounded,
    'AI & ML': Icons.psychology_rounded,
    'Electronics and Communication Engineering': Icons.sensors_rounded,
    'Electrical Engineering': Icons.electric_bolt_rounded,
    'Electronics and Instrumentation Engineering': Icons.speed_rounded,
    'Electronics Engineering (VLSI Design and Semiconductor Technology)': Icons.developer_board_rounded,
    'Mechanical Engineering': Icons.precision_manufacturing_rounded,
    'Chemical Engineering': Icons.science_rounded,
    'Civil Engineering': Icons.architecture_rounded,
  };

  final Map<String, IconData> _timeIcons = {
    'default': Icons.event_rounded,
  };

  // Colors
  final Color nirmaNavy = const Color(0xFF1A2B48);
  final Color nirmaRed = const Color(0xFFC62828); // Vibrant Hub Red
  final Color textDark = const Color(0xFF0F172A);
  final Color textGray = const Color(0xFF64748B);
  final Color borderGray = const Color(0xFFCBD5E1);
  final Color inputFill = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _domainShakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _domainShakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _domainShakeController, curve: Curves.easeInOut));

    // Default generating a 5 year window limit starting from today
    final currentYear = DateTime.now().year;
    _gradYears = List.generate(5, (index) => (currentYear + index).toString());
    
    // Automatically set Graduation value corresponding to 1st year initially
    _handleAcademicYearSelection('1st');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _divController.dispose();
    _batchController.dispose();
    _scrollController.dispose();
    _domainShakeController.dispose();
    super.dispose();
  }

  void _handleAcademicYearSelection(String yearString) {
    setState(() {
      _selectedYear = yearString;
      // Extract numerical prefix ('1', '2', '3', '4')
      int yearNum = int.tryParse(yearString[0]) ?? 1;
      
      // If they are in 1st year -> current + 4. 4th year -> current + 1.
      final offset = 5 - yearNum;
      
      _selectedGradYear = (DateTime.now().year + offset).toString();
    });
  }

  void _handleRegister() {
    setState(() => _isLoginAction = false);
    if (_formKey.currentState!.validate()) {
      if (_selectedGradYear == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Please select your Graduation Year.'), backgroundColor: nirmaRed),
        );
        return;
      }
      if (_selectedBranch == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Please select a Branch.'), backgroundColor: nirmaRed),
        );
        return;
      }
      
      setState(() {
        _isLoginAction = false;
        _buttonPressed = true;
      });
      
      ref.read(authNotifierProvider.notifier).registerUser(
        fullName: _nameController.text.trim(),
        rollNo: _rollController.text.trim(),
        academicYear: _selectedYear,
        graduationYear: _selectedGradYear!,
        division: _divController.text.trim(),
        batch: _batchController.text.trim(),
        branch: _selectedBranch!,
      );
    }
  }

  void _handleExistingLogin() {
    setState(() {
      _isLoginAction = true;
      _buttonPressed = true;
    });
    ref.read(authNotifierProvider.notifier).loginExistingUser();
  }

  Future<void> _openSelectorModal({
    required String title,
    required List<String> items,
    required String? currentValue,
    required Map<String, IconData> iconsMap,
    required bool activateSearch,
    required void Function(String) onSelected,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus(); // Force keyboard dismissal safely

    final Color nirmaRedTheme = const Color(0xFFC62828);
    final Color nirmaNavyTheme = const Color(0xFF1A2B48);
    final Color textDarkTheme = const Color(0xFF1E293B);
    final Color textGrayTheme = const Color(0xFF64748B);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Frosted glass foundation
      builder: (context) {
        return _GenericSelectorModal(
          title: title,
          items: items,
          selectedItem: currentValue,
          iconsMap: iconsMap,
          enableSearch: activateSearch,
          nirmaRed: nirmaRedTheme,
          nirmaNavy: nirmaNavyTheme,
          textDark: textDarkTheme,
          textGray: textGrayTheme,
        );
      },
    );

    if (result != null) {
      onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<void>>(
      authNotifierProvider,
      (_, state) {
        if (!state.isLoading && state.hasError) {
          final errorMsg = state.error.toString();
          final lowerError = errorMsg.toLowerCase();
          
          if (lowerError.contains('cancel') || lowerError.contains('popup_closed_by_user')) {
            // User backed out of Google pop-up. Act normally (do nothing).
            return;
          }

          if (lowerError.contains('nirma id (@nirmauni')) {
            _domainShakeController.forward(from: 0);
            return; // Show the shaking text, no popup!
          }
          
          if (errorMsg.contains('REDIRECT_TO_SIGNUP')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('You don\'t have an account yet. Please fill out the registration form below.'), backgroundColor: nirmaRed),
            );
            // Auto scroll down to the first field (Full Name)
            _scrollController.animateTo(200, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
            return;
          }
          
          if (errorMsg.contains('REDIRECT_TO_LOGIN')) {
            final email = errorMsg.split(':').last.replaceAll('Exception', '').trim();
            
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
                      ]
                    ),
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 14, bottom: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Slide indicator
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            height: 4,
                            width: 48,
                            decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                        const Icon(Icons.account_circle_rounded, color: Color(0xFF1A2B48), size: 56),
                        const SizedBox(height: 16),
                        const Text(
                          'Account Already Exists',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'An account is already linked to\n$email',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.4),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _scrollController.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A2B48),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Go to Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
            return;
          }

          _showAnimatedErrorDialog(context, errorMsg);
        }
      },
    );

    final Color nirmaRedTheme = const Color(0xFFC62828);
    final Color beamColor = widget.isSuccessMode 
        ? const Color(0xFF10B981) 
        : (isLoading && _buttonPressed ? const Color(0xFFF59E0B) : nirmaRedTheme);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F4F9), // Slate 100 bgSurface
        body: Stack(
        children: [
          // ── ULTRA-PREMIUM SUBTLE AMBIENT BACKGROUND ──
          const Positioned.fill(child: _PremiumAnimatedBackground()),
          
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 20.0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 450, // Optimal reading boundaries
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 6)),
                        ],
                        border: Border.all(color: borderGray.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Shrink to fit content
                        children: [
                          // ── Pinned Clean Header ──
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                            child: DynamicGraduationLogo(beamColor: beamColor),
                          ),
                          
                          // ── Scrollable Form Area ──
                          Flexible(
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(left: 28.0, right: 28.0, bottom: 24.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ─────────────────────────────────────────────────────────
                      // SECTION 1: EXISTING USERS
                      // ─────────────────────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        decoration: BoxDecoration(
                          color: inputFill,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderGray.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Already have an account?',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDark),
                            ),
                            const SizedBox(height: 16),
                            Builder(
                              builder: (context) {
                                final isLoginLoading = isLoading && _isLoginAction && _buttonPressed;
                                final isLoginSuccess = widget.isSuccessMode && _isLoginAction;
                                
                                Color loginBgColor = nirmaRed.withValues(alpha: 0.06); // Glassy light red
                                Color loginBorderColor = nirmaRed.withValues(alpha: 0.15);
                                if (isLoginLoading) {
                                  loginBgColor = Colors.white;
                                  loginBorderColor = borderGray;
                                } else if (isLoginSuccess) {
                                  loginBgColor = const Color(0xFFD1FAE5);
                                  loginBorderColor = const Color(0xFFA7F3D0);
                                }

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    color: loginBgColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: loginBorderColor, width: 1.2),
                                  ),
                                  child: OutlinedButton(
                                    onPressed: () {
                                      if (isLoading || widget.isSuccessMode) return;
                                      _handleExistingLogin();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.transparent, // Background handled by AnimatedContainer
                                      side: BorderSide.none, // Border handled by AnimatedContainer
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ).copyWith(
                                      overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                                        if (states.contains(WidgetState.pressed)) {
                                          return nirmaRed.withValues(alpha: 0.15);
                                        }
                                        if (states.contains(WidgetState.hovered)) {
                                          return nirmaRed.withValues(alpha: 0.05);
                                        }
                                        return null;
                                      }),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Invisible structure to keep the exact button size
                                        Opacity(
                                          opacity: 0.0,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              CustomPaint(size: const Size(20, 20), painter: _GoogleIconPainter()),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Continue with Nirma ID',
                                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: nirmaNavy),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: Center(
                                            child: AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 50),
                                              child: isLoginLoading
                                                  ? Row(
                                                      key: const ValueKey('loading'),
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706))),
                                                        const SizedBox(width: 10),
                                                        const Text('Loading...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
                                                      ],
                                                    )
                                                  : isLoginSuccess
                                                      ? Row(
                                                          key: const ValueKey('success'),
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            const Icon(Icons.verified, color: Color(0xFF059669), size: 22),
                                                            const SizedBox(width: 10),
                                                            const Text('Access Granted', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                                                          ],
                                                        )
                                                      : Row(
                                                          key: const ValueKey('idle'),
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            CustomPaint(size: const Size(20, 20), painter: _GoogleIconPainter()),
                                                            const SizedBox(width: 12),
                                                            Text(
                                                              'Continue with Nirma ID',
                                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: nirmaNavy),
                                                            ),
                                                          ],
                                                        ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            ),
                          ],
                        ),
                      ),
                      
                      // ── Shaking Nirma ID Enforcement Text ──
                      AnimatedBuilder(
                        animation: _domainShakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_domainShakeAnimation.value, 0),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                '* Only login with Nirma ID',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: nirmaRed.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          );
                        }
                      ),
                      
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: Divider(color: borderGray.withValues(alpha: 0.5), thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0),
                            child: Text(
                              'Or setup a new profile',
                              style: TextStyle(fontSize: 12, color: textGray, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(child: Divider(color: borderGray.withValues(alpha: 0.5), thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ─────────────────────────────────────────────────────────
                      // SECTION 2: NEW USER DETAILS
                      // ─────────────────────────────────────────────────────────
                      
                      _buildLabel('Full Name'),
                      _buildTextField(
                        controller: _nameController, 
                        hint: 'Your Name',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 12),

                      _buildLabel('Roll No'),
                      _buildTextField(
                        controller: _rollController, 
                        hint: 'E.g. 25BCE000',
                        prefixIcon: Icons.badge_outlined,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(9),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            String text = newValue.text;
                            if (text.isEmpty) return newValue;

                            String newText = '';
                            for (int i = 0; i < text.length; i++) {
                              String char = text[i];
                              if (i < 2) {
                                if (RegExp(r'^[0-9]$').hasMatch(char)) {
                                  newText += char;
                                } else { return oldValue; }
                              } else if (i < 5) {
                                if (RegExp(r'^[a-zA-Z]$').hasMatch(char)) {
                                  newText += char.toUpperCase();
                                } else { return oldValue; }
                              } else if (i < 9) {
                                if (RegExp(r'^[0-9]$').hasMatch(char)) {
                                  newText += char;
                                } else { return oldValue; }
                              }
                            }
                            
                            return TextEditingValue(
                              text: newText,
                              selection: newValue.selection.copyWith(
                                baseOffset: newText.length < newValue.selection.baseOffset ? newText.length : newValue.selection.baseOffset,
                                extentOffset: newText.length < newValue.selection.extentOffset ? newText.length : newValue.selection.extentOffset,
                              ),
                            );
                          }),
                        ],
                        validator: (String? value) {
                          if (value == null || value.trim().length < 8) return 'Require 8-9 chars';
                          if (!RegExp(r'^\d{2}[A-Z]{3}\d{3,4}$').hasMatch(value.trim())) {
                            return 'Format: 21BCE012';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // ACADEMIC YEAR (Swapped above form Grad year)
                      _buildLabel('Academic Year'),
                      _buildFixedChipGroup(
                        items: const ['1st', '2nd', '3rd', '4th'],
                        selected: _selectedYear,
                        onSelect: _handleAcademicYearSelection,
                      ),
                      const SizedBox(height: 12),

                      // GRADUATION YEAR (dynamically linked but user editable)
                      _buildLabel('Graduation Year'),
                      _buildPremiumSelectorField(
                        hint: 'Select Graduation Year',
                        value: _selectedGradYear,
                        prefixIcon: Icons.calendar_month_rounded, // Premium Time indicator
                        onTap: () => _openSelectorModal(
                          title: 'Select Year',
                          items: _gradYears,
                          currentValue: _selectedGradYear,
                          iconsMap: _timeIcons, 
                          activateSearch: false, 
                          onSelected: (val) => setState(() => _selectedGradYear = val),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Row: Division & Batch
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Division'),
                                _buildTextField(
                                  controller: _divController, 
                                  hint: 'E.g. D',
                                  prefixIcon: Icons.class_outlined,
                                  onChanged: (_) => setState(() {}),
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(1),
                                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                                    TextInputFormatter.withFunction((oldValue, newValue) {
                                      return newValue.copyWith(text: newValue.text.toUpperCase());
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Batch'),
                                _buildTextField(
                                  controller: _batchController,
                                  hint: 'E.g. D1',
                                  prefixIcon: Icons.group_outlined,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(3),
                                    TextInputFormatter.withFunction((oldValue, newValue) {
                                      String text = newValue.text;
                                      if (text.isEmpty) return newValue;

                                      // 1st char: Letter only
                                      if (!RegExp(r'^[a-zA-Z]$').hasMatch(text[0])) {
                                        return oldValue;
                                      }
                                      String newText = text[0].toUpperCase();

                                      // 2nd char: Number only
                                      if (text.length > 1) {
                                        if (RegExp(r'^[0-9]$').hasMatch(text[1])) {
                                          newText += text[1];
                                        } else {
                                          return oldValue;
                                        }
                                      }

                                      // 3rd char: Number only
                                      if (text.length > 2) {
                                        if (RegExp(r'^[0-9]$').hasMatch(text[2])) {
                                          newText += text[2];
                                        } else {
                                          return oldValue;
                                        }
                                      }

                                      return TextEditingValue(
                                        text: newText,
                                        selection: newValue.selection.copyWith(
                                          baseOffset: newText.length < newValue.selection.baseOffset ? newText.length : newValue.selection.baseOffset,
                                          extentOffset: newText.length < newValue.selection.extentOffset ? newText.length : newValue.selection.extentOffset,
                                        ),
                                      );
                                    }),
                                  ],
                                  validator: (String? value) {
                                    if (value == null || value.trim().length < 2) return 'Require 2-3 chars';
                                    final div = _divController.text.trim().toUpperCase();
                                    if (div.isNotEmpty && !value.toUpperCase().startsWith(div)) {
                                      return 'Starts with $div';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // BRANCH
                      _buildLabel('Branch (B. Tech)'),
                      _buildPremiumSelectorField(
                        hint: 'Select Branch',
                        value: _selectedBranch,
                        prefixIcon: _selectedBranch != null ? _branchIcons[_selectedBranch] : Icons.layers_outlined,
                        onTap: () => _openSelectorModal(
                          title: 'Select Branch',
                          items: _customBranches,
                          currentValue: _selectedBranch,
                          iconsMap: _branchIcons, 
                          activateSearch: true,
                          onSelected: (val) => setState(() => _selectedBranch = val),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Register Action Button ──
                      Builder(
                        builder: (context) {
                          final isRegLoading = isLoading && !_isLoginAction && _buttonPressed;
                          final isRegSuccess = widget.isSuccessMode && !_isLoginAction;

                          Color regBgColor = nirmaNavy;
                          Color regBorderColor = Colors.transparent;
                          if (isRegSuccess) {
                            regBgColor = const Color(0xFFD1FAE5);
                            regBorderColor = const Color(0xFFA7F3D0);
                          } else if (isRegLoading) {
                            regBgColor = Colors.white;
                            regBorderColor = borderGray;
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: regBgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: regBorderColor, width: 1.2),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (isLoading || widget.isSuccessMode) return;
                                _handleRegister();
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.transparent, 
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Opacity(
                                    opacity: 0.0,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CustomPaint(size: const Size(20, 20), painter: _GoogleIconPainter()),
                                        const SizedBox(width: 12),
                                        const Text('Register with Nirma ID', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Center(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 50),
                                        child: isRegSuccess
                                            ? Row(
                                                key: const ValueKey('success'),
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.verified, color: Color(0xFF059669), size: 22),
                                                  const SizedBox(width: 10),
                                                  const Text('Access Granted', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                                                ],
                                              )
                                            : isRegLoading
                                                ? Row(
                                                    key: const ValueKey('loading'),
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706))),
                                                      const SizedBox(width: 10),
                                                      const Text('Loading...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
                                                    ],
                                                  )
                                                : Row(
                                                    key: const ValueKey('idle'),
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      CustomPaint(size: const Size(20, 20), painter: _GoogleIconPainter()),
                                                      const SizedBox(width: 12),
                                                      const Text('Register with Nirma ID', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                                    ],
                                                  ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      ),
                      
                      // ── Shaking Nirma ID Enforcement Text ──
                      AnimatedBuilder(
                        animation: _domainShakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_domainShakeAnimation.value, 0),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                '* Only register with Nirma ID',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: nirmaRed.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          );
                        }
                      ),
                      
                      const SizedBox(height: 24),

                      // ── Help & Support ──
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please contact IT Support at backlogon@gmail.com for assistance with Nirma ID.'),
                                backgroundColor: nirmaNavy,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          icon: Icon(Icons.help_outline_rounded, size: 16, color: nirmaNavy),
                          label: Text(
                            'Need help with login?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: nirmaNavy,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      // ── Terms & Privacy Footer ──
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'By continuing, you agree to Nirma Hub\'s\n',
                            style: TextStyle(fontSize: 12, color: textGray, height: 1.5),
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(color: nirmaRed, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    final Uri url = Uri.parse('https://www.nirma-hub.online/terms.html');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    }
                                  },
                              ),
                              const TextSpan(text: '  and  '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(color: nirmaRed, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    final Uri url = Uri.parse('https://www.nirma-hub.online/privacy-policy.html');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    }
                                  },
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // PREMIUM 3D BOOKMARK
                Positioned(
                  top: -6,
                  left: 24, // Shifted further left away from center HUB
                  child: CustomPaint(
                    size: const Size(28, 52), // Thinner ribbon
                    painter: _BookmarkPainter(color: const Color(0xFFC62828)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      
    ],
  ),
),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // REUSABLE COMPONENTS & ANIMATIONS
  // ─────────────────────────────────────────────────────────────

  void _showAnimatedErrorDialog(BuildContext context, String message) {
    // Clean up Supabase/Exception text prefixes for a better user experience
    String cleanMessage = message.replaceAll('Exception: ', '').replaceAll('AuthException', '').trim();
    if (cleanMessage.startsWith(RegExp(r'^[\W_]+'))) {
      cleanMessage = cleanMessage.replaceFirst(RegExp(r'^[\W_]+'), '').trim();
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC62828).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828), size: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text('Authentication Failed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              content: Text(
                cleanMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF64748B)),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2B48),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Okay', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      validator: validator ?? (value) => value == null || value.trim().isEmpty ? 'Required' : null,
      onChanged: onChanged,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textDark),
      cursorColor: nirmaRed,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(color: textGray.withValues(alpha: 0.6), fontSize: 14),
        filled: true,
        fillColor: inputFill,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: textGray.withValues(alpha: 0.8), size: 20) : null,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: prefixIcon != null ? 14 : 14), 
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderGray.withValues(alpha: 0.6), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: nirmaRed, width: 1.8),
        ),
        errorMaxLines: 2,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC62828), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC62828), width: 1.8),
        ),
      ),
    );
  }

  // Shared UI for Year & Branch (Now supporting inner prefixes)
  Widget _buildPremiumSelectorField({
    required String hint,
    required String? value,
    IconData? prefixIcon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderGray.withValues(alpha: 0.6), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, color: value == null ? textGray.withValues(alpha: 0.8) : nirmaNavy.withValues(alpha: 0.9), size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: value == null ? FontWeight.normal : FontWeight.w500,
                  color: value == null ? textGray.withValues(alpha: 0.6) : textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.unfold_more_rounded, color: textGray, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedChipGroup({
    required List<String> items,
    required String selected,
    required Function(String) onSelect,
  }) {
    return Row(
      children: items.map((item) {
        final isSelected = selected == item;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: InkWell(
              onTap: () => onSelect(item),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? nirmaRed : inputFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? nirmaRed : borderGray.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : textDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// REUSABLE GENERIC SELECTOR MODAL (Branch & Year specific UI)
// ─────────────────────────────────────────────────────────────
class _GenericSelectorModal extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selectedItem;
  final Map<String, IconData> iconsMap;
  final bool enableSearch;
  
  final Color nirmaRed;
  final Color nirmaNavy;
  final Color textDark;
  final Color textGray;

  const _GenericSelectorModal({
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.iconsMap,
    required this.enableSearch,
    required this.nirmaRed,
    required this.nirmaNavy,
    required this.textDark,
    required this.textGray,
  });

  @override
  State<_GenericSelectorModal> createState() => _GenericSelectorModalState();
}

class _GenericSelectorModalState extends State<_GenericSelectorModal> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Premium Glassmorphism blurring background screen
      child: Container(
        height: MediaQuery.of(context).size.height * (widget.enableSearch ? 0.70 : 0.45), // Adjusts scaling based on needs
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
          ]
        ),
        child: Column(
          children: [
            // Slide indicator
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 14, bottom: 8),
                height: 4,
                width: 48,
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            
            // Header Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: widget.textDark),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: widget.textGray),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Optional Search Bar
            if (widget.enableSearch)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  cursorColor: widget.nirmaRed,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: widget.textGray.withValues(alpha: 0.6)),
                    prefixIcon: Icon(Icons.search_rounded, color: widget.textGray),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: const Color(0xFFCBD5E1).withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: widget.nirmaRed, width: 1.5),
                    ),
                  ),
                ),
              ),
            
            if (widget.enableSearch)
              const SizedBox(height: 12),
            
            Divider(color: const Color(0xFFF1F4F9), thickness: 2, height: 0),
            
            // Scaled list rendering
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(child: Text("No items found.", style: TextStyle(color: widget.textGray)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = item == widget.selectedItem;
                        
                        // Extracting map fallback icon explicitly
                        IconData targetIcon = widget.iconsMap[item] ?? widget.iconsMap['default'] ?? Icons.circle_outlined;
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          tileColor: isSelected ? widget.nirmaRed.withValues(alpha: 0.05) : Colors.transparent, // Highlight background
                          onTap: () => Navigator.pop(context, item), // Return result
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? widget.nirmaRed.withValues(alpha: 0.1) : const Color(0xFFF1F4F9),
                            radius: 20,
                            child: Icon(
                              targetIcon, 
                              color: isSelected ? widget.nirmaRed : widget.textGray.withValues(alpha: 0.6), 
                              size: 20
                            ),
                          ),
                          title: Text(
                            item,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? widget.textDark : widget.textDark.withValues(alpha: 0.8),
                            ),
                          ),
                          trailing: isSelected 
                            ? Icon(Icons.check_circle_rounded, color: widget.nirmaRed, size: 24)
                            : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PREMUM APPLE-STYLE ULTRA-LOW OPACITY BACKGROUND
// ─────────────────────────────────────────────────────────────
class _PremiumAnimatedBackground extends StatefulWidget {
  const _PremiumAnimatedBackground();
  @override
  State<_PremiumAnimatedBackground> createState() => _PremiumAnimatedBackgroundState();
}

class _PremiumAnimatedBackgroundState extends State<_PremiumAnimatedBackground> {
  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFF1F4F9));
  }
}

// ─────────────────────────────────────────────────────────────
// CAP + LIGHT BEAM HEADER (Dynamic Version)
// ─────────────────────────────────────────────────────────────
class DynamicGraduationLogo extends StatelessWidget {
  final Color beamColor;
  const DynamicGraduationLogo({super.key, required this.beamColor});

  @override
  Widget build(BuildContext context) {
    final Color nirmaNavy = const Color(0xFF1A2B48);
    final Color nirmaRed = const Color(0xFFC62828);

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'NIRMA',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: nirmaNavy,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),

          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                top: -40, // Match cap drop
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(begin: nirmaRed, end: beamColor),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, color, child) {
                    return CustomPaint(
                      size: const Size(64, 48),
                      painter: _LightBeamPainter(color: (color ?? nirmaRed).withValues(alpha: 0.35)),
                    );
                  },
                ),
              ),
              Positioned(
                top: -53, // Micro-nudged physically downwards closer to HUB
                child: Transform.rotate(
                  angle: 0.12,
                  child: const Icon(Icons.school, color: Color(0xFF0F172A), size: 36),
                ),
              ),
              Text(
                'HUB',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: nirmaRed,
                  shadows: [
                    Shadow(color: nirmaRed.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2)) // Much sharper, cleaner shadow preventing blurriness
                  ]
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _LightBeamPainter extends CustomPainter {
  final Color color;
  _LightBeamPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.35, 0)
      ..lineTo(size.width * 0.65, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant _LightBeamPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────
// BOOKMARK RIBBON PAINTER
// ─────────────────────────────────────────────────────────────
class _BookmarkPainter extends CustomPainter {
  final Color color;
  _BookmarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Elegant bookmark hanging from top
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height - 12)
      ..lineTo(0, size.height)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Add specular highlight making it look like premium satin/paper
    paint.shader = LinearGradient(
      colors: [
        color,
        HSLColor.fromColor(color).withLightness(0.55).toColor(),
        color,
      ],
      stops: const [0.0, 0.4, 1.0],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);

    // 3D Corner fold graphic showing it wraps behind the paper
    final foldPath = Path()
      ..moveTo(0, 0)
      ..lineTo(-8, 8)
      ..lineTo(0, 8)
      ..close();
    
    final foldPaint = Paint()
      ..color = HSLColor.fromColor(color).withLightness(0.25).toColor();
    
    canvas.drawPath(foldPath, foldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// GOOGLE ICON PAINTER
// ─────────────────────────────────────────────────────────────
class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final double scale = size.width / 24.0;
    canvas.scale(scale);

    paint.color = const Color(0xFF4285F4);
    var p1 = Path()..moveTo(23.5, 12.2)..cubicTo(23.5, 11.4, 23.4, 10.6, 23.3, 9.9)..lineTo(12, 9.9)..lineTo(12, 14.3)..lineTo(18.4, 14.3)..cubicTo(18.1, 15.8, 17.3, 17.1, 16, 17.9)..lineTo(16, 20.9)..lineTo(19.8, 20.9)..cubicTo(22, 18.8, 23.5, 15.8, 23.5, 12.2);
    canvas.drawPath(p1, paint);

    paint.color = const Color(0xFF34A853);
    var p2 = Path()..moveTo(12, 24)..cubicTo(15.2, 24, 18, 23.9, 20.1, 21)..lineTo(16, 18)..cubicTo(14.9, 18.8, 13.4, 19.3, 11.7, 19.3)..cubicTo(8.4, 19.3, 5.6, 17.1, 4.6, 14.1)..lineTo(0.8, 17.2)..cubicTo(2.8, 21.1, 6.9, 24, 12, 24);
    canvas.drawPath(p2, paint);

    paint.color = const Color(0xFFFBBC05);
    var p3 = Path()..moveTo(4.9, 14.1)..cubicTo(4.7, 13.5, 4.5, 12.8, 4.5, 12)..cubicTo(4.5, 11.2, 4.7, 10.5, 4.9, 9.9)..lineTo(4.9, 6.8)..lineTo(1.1, 6.8)..cubicTo(0.4, 8.4, 0, 10.1, 0, 12)..cubicTo(0, 13.9, 0.4, 15.6, 1.1, 17.2)..lineTo(4.9, 14.1);
    canvas.drawPath(p3, paint);

    paint.color = const Color(0xFFEA4335);
    var p4 = Path()..moveTo(12, 4.7)..cubicTo(13.7, 4.7, 15.3, 5.3, 16.6, 6.5)..lineTo(20, 3.1)..cubicTo(17.9, 1.2, 15.2, 0, 12, 0)..cubicTo(7.2, 0, 3.1, 2.9, 1.1, 6.8)..lineTo(4.9, 9.9)..cubicTo(5.9, 6.9, 8.7, 4.7, 12, 4.7);
    canvas.drawPath(p4, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
