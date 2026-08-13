import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import '../features/timetable/domain/timetable_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (e) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (e2) {
        // Fallback to UTC if even Asia/Kolkata fails
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap if needed
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _isInitialized = true;
  }

  void listenForAppNotifications() {
    Supabase.instance.client
        .channel('public:app_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'app_notifications',
          callback: (payload) async {
            final newRecord = payload.newRecord;
            if (newRecord != null) {
              final targetYear = newRecord['target_year'] as String? ?? 'All';
              
              if (targetYear != 'All') {
                try {
                  final prefs = await SharedPreferences.getInstance();
                  final userYear = prefs.getString('academic_year');
                  if (userYear != targetYear) {
                    return; // Skip if it's not for this user's year
                  }
                } catch (e) {
                  // If we can't read prefs, maybe skip or show. Let's show by default if error.
                  print('Error reading SharedPreferences for notification target: $e');
                }
              }

              _showImmediateNotification(
                newRecord['title'] ?? 'New Notification',
                newRecord['message'] ?? '',
              );
            }
          },
        )
        .subscribe();
  }

  Future<void> _showImmediateNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'general_notifications_channel',
      'General Notifications',
      channelDescription: 'Important updates and new items',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFC62828),
      enableVibration: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final uniqueId = Random().nextInt(100000);
    await flutterLocalNotificationsPlugin.show(
      id: uniqueId,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<bool> checkAndRequestPermission(BuildContext context, {bool showDialogIfDenied = true}) async {
    if (!Platform.isAndroid) return false;

    PermissionStatus status = await Permission.notification.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.notification.request();
      if (status.isGranted) return true;
    }

    if ((status.isPermanentlyDenied || status.isDenied) && showDialogIfDenied && context.mounted) {
      _showPermissionDialog(context);
    }

    return status.isGranted;
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 32,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Don't Miss a Class!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'Manrope',
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Enable notifications to get a reminder 10 minutes before your lectures start. We'll tell you the subject, professor, and location so you're always prepared.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                  fontFamily: 'Manrope',
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Open Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text("Maybe Later", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _dayStringToInt(String day) {
    switch (day.toUpperCase()) {
      case 'MON': return DateTime.monday;
      case 'TUE': return DateTime.tuesday;
      case 'WED': return DateTime.wednesday;
      case 'THU': return DateTime.thursday;
      case 'FRI': return DateTime.friday;
      case 'SAT': return DateTime.saturday;
      case 'SUN': return DateTime.sunday;
      default: return DateTime.monday;
    }
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

  Future<void> scheduleTimetableNotifications(List<TimetableEntry> entries) async {
    if (!Platform.isAndroid) return;
    
    final status = await Permission.notification.status;
    if (!status.isGranted) return;

    await flutterLocalNotificationsPlugin.cancelAll();

    // Group by day to find the first class
    final Map<String, List<TimetableEntry>> entriesByDay = {};
    for (var entry in entries) {
      if (entry.startTime.isNotEmpty && entry.startTime != "All Day") {
        entriesByDay.putIfAbsent(entry.day, () => []).add(entry);
      }
    }
    
    // Sort each day's classes by time
    for (var day in entriesByDay.keys) {
      entriesByDay[day]!.sort((a, b) => _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)));
    }

    for (var day in entriesByDay.keys) {
      var dayEntries = entriesByDay[day]!;
      
      // Find the first REAL lecture of the day
      TimetableEntry? firstRealLecture;
      for (var dEntry in dayEntries) {
        bool dIsFree = dEntry.subject.toLowerCase().contains('free') || dEntry.subject.toLowerCase().contains('break');
        if (!dIsFree) {
          firstRealLecture = dEntry;
          break;
        }
      }

      // Consolidate consecutive real classes for the day
      List<TimetableEntry> consolidatedClasses = [];
      for (int i = 0; i < dayEntries.length; i++) {
        var entry = dayEntries[i];
        bool isFree = entry.subject.toLowerCase().contains('free') || entry.subject.toLowerCase().contains('break');
        if (isFree) continue;

        if (consolidatedClasses.isNotEmpty && consolidatedClasses.last.subject == entry.subject) {
          // Merge with previous block
          consolidatedClasses.last = TimetableEntry(
            academicYear: consolidatedClasses.last.academicYear,
            branch: consolidatedClasses.last.branch,
            division: consolidatedClasses.last.division,
            batch: consolidatedClasses.last.batch,
            day: consolidatedClasses.last.day,
            subject: consolidatedClasses.last.subject,
            startTime: consolidatedClasses.last.startTime,
            endTime: entry.endTime,
            professor: consolidatedClasses.last.professor,
            location: consolidatedClasses.last.location,
          );
        } else {
          consolidatedClasses.add(entry);
        }
      }

      for (int i = 0; i < consolidatedClasses.length; i++) {
        var entry = consolidatedClasses[i];
        
        final startMinutes = _timeToMinutes(entry.startTime);
        final endMinutes = _timeToMinutes(entry.endTime);
        if (startMinutes == 0 || endMinutes == 0) continue;

        bool isFirstRealClass = firstRealLecture != null && startMinutes == _timeToMinutes(firstRealLecture.startTime);

        final dayOfWeek = _dayStringToInt(entry.day);
        final Int64List vibrationPattern = Int64List(2);
        vibrationPattern[0] = 0;
        vibrationPattern[1] = 1000;

        final String formattedSubject = _getFormattedSubjectName(entry.subject);
          
        int notificationMinutes;
        String contentTitle;
        
        if (isFirstRealClass) {
          notificationMinutes = startMinutes - 20;
          contentTitle = '$formattedSubject starting in 20 mins!';
        } else {
          // Send notification 10 minutes before the PREVIOUS class ends
          final previousClass = consolidatedClasses[i - 1];
          notificationMinutes = _timeToMinutes(previousClass.endTime) - 10;
          contentTitle = '$formattedSubject starting in 10 mins!';
        }
        
        final hour = notificationMinutes ~/ 60;
        final minute = notificationMinutes % 60;
        tz.TZDateTime scheduledDate = _nextInstanceOfDayAndTime(dayOfWeek, hour, minute);

        String bodyText = '👨‍🏫 Prof: ${entry.professor}   📍 Location: <b>${entry.location}</b>';
        String bigText = '👨‍🏫 Prof: ${entry.professor}<br>📍 Location: <b>${entry.location}</b>';

        final BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
          bigText,
          htmlFormatBigText: true,
          contentTitle: contentTitle,
          htmlFormatContentTitle: true,
          summaryText: isFirstRealClass ? 'First Class' : 'Next Class',
          htmlFormatSummaryText: true,
          htmlFormatContent: true,
          htmlFormatTitle: true,
        );

        final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'timetable_channel', 
          'Class Reminders',
          channelDescription: 'Notifications for classes',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Class Reminder',
          color: const Color(0xFF3B82F6),
          vibrationPattern: vibrationPattern,
          enableVibration: true,
          styleInformation: bigTextStyleInformation,
        );

        int uniqueId = (entry.day + entry.startTime).hashCode % 100000;
        try {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id: uniqueId,
            title: contentTitle,
            body: bodyText,
            scheduledDate: scheduledDate,
            notificationDetails: NotificationDetails(android: androidPlatformChannelSpecifics),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
          
          print("🔔 [DEBUG] LECTURE NOTIFICATION SCHEDULED SUCCESSFULLY:");
          print("   Title: $contentTitle");
          print("   Target Time: ${scheduledDate.toString()}");

          // Save to SharedPreferences for Debug Screen
          final prefs = await SharedPreferences.getInstance();
          final logs = prefs.getStringList('notification_debug_logs') ?? [];
          final logEntry = "${DateTime.now().toString().split('.')[0]}|Scheduled '$contentTitle' for ${scheduledDate.toString()}";
          logs.add(logEntry);
          // Keep only last 50 logs
          if (logs.length > 50) logs.removeAt(0);
          await prefs.setStringList('notification_debug_logs', logs);

        } catch (e) {
          print("Failed to schedule notification: $e");
        }
      }
    }
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    
    return scheduledDate;
  }

  String _getFormattedSubjectName(String subject) {
    if (subject.isEmpty) return subject;
    
    final ignoreWords = ['and', 'of', 'the', 'in', 'for', 'to', 'with', 'or', 'a', 'an', '&'];
    final words = subject.split(RegExp(r'[\s\-]+')).where((w) => w.isNotEmpty).toList();
    
    if (words.length <= 1) {
      return subject; // E.g. "Mathematics" -> just return "Mathematics"
    }
    
    String acronym = "";
    for (var word in words) {
      if (!ignoreWords.contains(word.toLowerCase())) {
        acronym += word[0].toUpperCase();
      }
    }
    
    if (acronym.length > 1) {
      return "<b>$acronym</b> ($subject)";
    } else {
      return subject;
    }
  }
}
