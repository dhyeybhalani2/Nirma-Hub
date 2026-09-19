import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import '../features/timetable/domain/timetable_entry.dart';
import '../features/notifications/domain/notification_preferences.dart';
import '../features/events/data/events_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../core/theme/app_theme.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _isSchedulingTimetable = false;

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

    const AndroidNotificationChannel vibratingChannel = AndroidNotificationChannel(
      'timetable_channel_vibrating',
      'Class Reminders (Vibration)',
      description: 'Notifications for classes with vibration.',
      importance: Importance.high,
      enableVibration: true,
    );

    const AndroidNotificationChannel silentChannel = AndroidNotificationChannel(
      'timetable_channel_silent',
      'Class Reminders (No Vibration)',
      description: 'Notifications for classes without vibration.',
      importance: Importance.high,
      enableVibration: false,
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(vibratingChannel);
    await androidPlugin?.createNotificationChannel(silentChannel);

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
            if (newRecord.isNotEmpty) {
              final targetYear = newRecord['target_year'] as String? ?? 'All';
              
              if (targetYear != 'All') {
                try {
                  final prefs = await SharedPreferences.getInstance();
                  final userYear = prefs.getString('academic_year');
                  if (userYear != targetYear) {
                    return; // Skip if it's not for this user's year
                  }
                } catch (e) {
                  // If we can't read prefs, ignore error
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

  Future<void> sendTestNotification(TimetableNotificationSettings settings) async {
    final Int64List vibrationPattern = Int64List(2);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 1000;

    final String contentTitle = 'OOP starting in ${settings.firstClassReminder1Minutes} mins!';
    const String bodyText = '👨‍🏫 Prof: Dr. Sharma   📍 Location: <b>W408</b>';
    const String bigText = '👨‍🏫 Prof: Dr. Sharma<br>📍 Location: <b>W408</b>';

    final BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      bigText,
      htmlFormatBigText: true,
      contentTitle: contentTitle,
      htmlFormatContentTitle: true,
      summaryText: 'Class Reminder Preview',
      htmlFormatSummaryText: true,
      htmlFormatContent: true,
      htmlFormatTitle: true,
    );

    final String channelId = settings.enableVibration ? 'timetable_channel_vibrating' : 'timetable_channel_silent';
    final String channelName = settings.enableVibration ? 'Class Reminders' : 'Class Reminders (No Vibration)';

    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId, 
      channelName,
      channelDescription: 'Notifications for classes',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Class Reminder',
      color: const Color(0xFFC62828),
      vibrationPattern: settings.enableVibration ? vibrationPattern : null,
      enableVibration: settings.enableVibration,
      styleInformation: bigTextStyleInformation,
    );

    await flutterLocalNotificationsPlugin.show(
      id: 99999,
      title: contentTitle,
      body: bodyText,
      notificationDetails: NotificationDetails(android: androidPlatformChannelSpecifics),
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
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Don't Miss a Class!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Enable notifications to get a reminder before your lectures start. We'll tell you the subject, professor, and location so you're always prepared.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.c.dangerFill,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Open Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: context.c.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Maybe Later", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _intToDayString(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'MON';
      case DateTime.tuesday: return 'TUE';
      case DateTime.wednesday: return 'WED';
      case DateTime.thursday: return 'THU';
      case DateTime.friday: return 'FRI';
      case DateTime.saturday: return 'SAT';
      case DateTime.sunday: return 'SUN';
      default: return 'MON';
    }
  }

  EventModel? _getHolidayForDate(DateTime date, List<EventModel> allEvents) {
    final targetDate = DateTime(date.year, date.month, date.day);
    for (var event in allEvents) {
      if (event.category.trim().toLowerCase() == 'holiday') {
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
          return event;
        }
      }
    }
    return null;
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

  Future<void> scheduleTimetableNotifications(
    List<TimetableEntry> entries, {
    TimetableNotificationSettings? customSettings,
    List<EventModel>? events,
  }) async {
    if (!Platform.isAndroid) return;
    if (_isSchedulingTimetable) return;
    _isSchedulingTimetable = true;

    try {
      final settings = customSettings ?? await TimetableNotificationSettings.loadFromPrefs();

      // Check system permission
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        _isSchedulingTimetable = false;
        return;
      }

      // Always clear previous schedule to eliminate stale or repeating alarms
      await flutterLocalNotificationsPlugin.cancelAll();

      if (!settings.isEnabled || entries.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final logs = prefs.getStringList('notification_debug_logs') ?? [];
        logs.add("${DateTime.now().toString().split('.')[0]}|Timetable notifications disabled or empty");
        if (logs.length > 50) logs.removeAt(0);
        await prefs.setStringList('notification_debug_logs', logs);
        _isSchedulingTimetable = false;
        return;
      }

      // Fetch holiday events from Supabase if not provided
      List<EventModel> allEvents = events ?? [];
      if (allEvents.isEmpty) {
        try {
          allEvents = await EventsService().getAllEvents();
        } catch (_) {}
      }

      // Group entries by normalized uppercase day (e.g. MON, TUE, WED, THU, FRI)
      final Map<String, List<TimetableEntry>> entriesByDay = {};
      for (var entry in entries) {
        if (entry.startTime.isNotEmpty && entry.startTime != "All Day") {
          final normalizedDay = entry.day.toUpperCase().trim();
          entriesByDay.putIfAbsent(normalizedDay, () => []).add(entry);
        }
      }

      // Sort classes for each day by start time
      for (var day in entriesByDay.keys) {
        entriesByDay[day]!.sort((a, b) => _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)));
      }

      final Int64List vibrationPattern = Int64List(2);
      vibrationPattern[0] = 0;
      vibrationPattern[1] = 1000;

      final now = tz.TZDateTime.now(tz.local);
      final todayDate = DateTime.now();

      int scheduledCount = 0;

      debugPrint("════════════════════════════════════════════════════════════════");
      debugPrint("🔔 TIMETABLE NOTIFICATION SCHEDULER STARTED");
      debugPrint("⚙️ First Class: ${settings.firstClassReminder1Minutes}m | Subsequent: ${settings.subsequentReminder1Minutes}m | Vibration: ${settings.enableVibration}");
      debugPrint("────────────────────────────────────────────────────────────────");

      // Schedule for the upcoming 14 days, skipping weekends and holidays
      for (int dayOffset = 0; dayOffset < 14; dayOffset++) {
        final targetDate = todayDate.add(Duration(days: dayOffset));

        // Skip weekends
        if (targetDate.weekday == DateTime.saturday || targetDate.weekday == DateTime.sunday) {
          continue;
        }

        // Check if this date is a holiday
        final holiday = _getHolidayForDate(targetDate, allEvents);
        if (holiday != null) {
          // HOLIDAY DETECTED: Skip scheduling notifications for this entire day!
          continue;
        }

        final String dayKey = _intToDayString(targetDate.weekday);
        final dayEntries = entriesByDay[dayKey];
        if (dayEntries == null || dayEntries.isEmpty) continue;

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

        final datePrefix = "${targetDate.year}${targetDate.month.toString().padLeft(2, '0')}${targetDate.day.toString().padLeft(2, '0')}";

        for (int i = 0; i < consolidatedClasses.length; i++) {
          var entry = consolidatedClasses[i];

          final startMinutes = _timeToMinutes(entry.startTime);
          final endMinutes = _timeToMinutes(entry.endTime);
          if (startMinutes == 0 || endMinutes == 0) continue;

          bool isFirstRealClass = firstRealLecture != null && startMinutes == _timeToMinutes(firstRealLecture.startTime);
          final String formattedSubject = _getFormattedSubjectName(entry.subject);

          String bodyText = '👨‍🏫 Prof: ${entry.professor}   📍 Location: <b>${entry.location}</b>';
          String bigText = '👨‍🏫 Prof: ${entry.professor}<br>📍 Location: <b>${entry.location}</b>';

          // --- 1. PRIMARY REMINDER CALCULATION ---
          int primaryNotificationMinutes;
          String primaryContentTitle;

          if (isFirstRealClass) {
            final offset = settings.firstClassReminder1Minutes;
            primaryNotificationMinutes = startMinutes - offset;
            primaryContentTitle = '$formattedSubject starting in $offset mins!';
          } else {
            if (settings.subsequentUsePreviousEnd) {
              final previousClass = consolidatedClasses[i - 1];
              primaryNotificationMinutes = _timeToMinutes(previousClass.endTime) - 10;

              final gapMins = startMinutes - primaryNotificationMinutes;
              if (gapMins >= 60) {
                int hours = gapMins ~/ 60;
                int mins = gapMins % 60;
                if (mins == 0) {
                  primaryContentTitle = '$formattedSubject starting in $hours hr${hours > 1 ? 's' : ''}!';
                } else {
                  primaryContentTitle = '$formattedSubject starting in $hours hr${hours > 1 ? 's' : ''} $mins min!';
                }
              } else {
                primaryContentTitle = '$formattedSubject starting in $gapMins mins!';
              }
            } else {
              final offset = settings.subsequentReminder1Minutes;
              primaryNotificationMinutes = startMinutes - offset;
              primaryContentTitle = '$formattedSubject starting in $offset mins!';
            }
          }

          if (primaryNotificationMinutes > 0) {
            final hour = primaryNotificationMinutes ~/ 60;
            final minute = primaryNotificationMinutes % 60;
            final scheduledDate = tz.TZDateTime(
              tz.local,
              targetDate.year,
              targetDate.month,
              targetDate.day,
              hour,
              minute,
            );

            // Only schedule if the alarm is in the future
            if (scheduledDate.isAfter(now)) {
              final BigTextStyleInformation bigTextStyleInfo = BigTextStyleInformation(
                bigText,
                htmlFormatBigText: true,
                contentTitle: primaryContentTitle,
                htmlFormatContentTitle: true,
                summaryText: isFirstRealClass ? 'First Class' : 'Next Class',
                htmlFormatSummaryText: true,
                htmlFormatContent: true,
                htmlFormatTitle: true,
              );

              final String channelId = settings.enableVibration ? 'timetable_channel_vibrating' : 'timetable_channel_silent';
              final String channelName = settings.enableVibration ? 'Class Reminders' : 'Class Reminders (No Vibration)';

              final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
                channelId,
                channelName,
                channelDescription: 'Notifications for classes',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'Class Reminder',
                color: const Color(0xFFC62828),
                vibrationPattern: settings.enableVibration ? vibrationPattern : null,
                enableVibration: settings.enableVibration,
                styleInformation: bigTextStyleInfo,
              );

              int primaryId = ("${datePrefix}_${entry.startTime}_p1").hashCode.abs() % 1000000;
              try {
                await flutterLocalNotificationsPlugin.zonedSchedule(
                  id: primaryId,
                  title: primaryContentTitle,
                  body: bodyText,
                  scheduledDate: scheduledDate,
                  notificationDetails: NotificationDetails(android: androidDetails),
                  androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                );
                scheduledCount++;
                debugPrint("  ⏰ [ALARM #$primaryId] -> $formattedSubject on $dayKey at ${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')} (${entry.startTime} - ${entry.endTime}) [${entry.location}]");
              } catch (e) {
                // Ignore single failure
              }
            }
          }

          // --- 2. SECONDARY REMINDER CALCULATION (MAX 2 PER CLASS) ---
          bool hasSecondary = isFirstRealClass
              ? (settings.firstClassReminder2Enabled && settings.firstClassReminder2Minutes < settings.firstClassReminder1Minutes)
              : (settings.subsequentReminder2Enabled);

          if (hasSecondary) {
            final secondOffset = isFirstRealClass
                ? settings.firstClassReminder2Minutes
                : settings.subsequentReminder2Minutes;

            final secondNotificationMinutes = startMinutes - secondOffset;
            if (secondNotificationMinutes > 0) {
              final secondTitle = '$formattedSubject starts in $secondOffset mins! ⚡';
              final hour = secondNotificationMinutes ~/ 60;
              final minute = secondNotificationMinutes % 60;
              final secondScheduledDate = tz.TZDateTime(
                tz.local,
                targetDate.year,
                targetDate.month,
                targetDate.day,
                hour,
                minute,
              );

              if (secondScheduledDate.isAfter(now)) {
                final BigTextStyleInformation secondBigStyleInfo = BigTextStyleInformation(
                  bigText,
                  htmlFormatBigText: true,
                  contentTitle: secondTitle,
                  htmlFormatContentTitle: true,
                  summaryText: 'Final Reminder',
                  htmlFormatSummaryText: true,
                  htmlFormatContent: true,
                  htmlFormatTitle: true,
                );

                final String channelId = settings.enableVibration ? 'timetable_channel_vibrating' : 'timetable_channel_silent';
                final String channelName = settings.enableVibration ? 'Class Reminders' : 'Class Reminders (No Vibration)';

                final AndroidNotificationDetails secondAndroidDetails = AndroidNotificationDetails(
                  channelId,
                  channelName,
                  channelDescription: 'Notifications for classes',
                  importance: Importance.max,
                  priority: Priority.high,
                  ticker: 'Final Class Reminder',
                  color: const Color(0xFFC62828),
                  vibrationPattern: settings.enableVibration ? vibrationPattern : null,
                  enableVibration: settings.enableVibration,
                  styleInformation: secondBigStyleInfo,
                );

                int secondaryId = (("${datePrefix}_${entry.startTime}_p2").hashCode.abs() % 1000000) + 1000000;
                try {
                  await flutterLocalNotificationsPlugin.zonedSchedule(
                    id: secondaryId,
                    title: secondTitle,
                    body: bodyText,
                    scheduledDate: secondScheduledDate,
                    notificationDetails: NotificationDetails(android: secondAndroidDetails),
                    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                  );
                  scheduledCount++;
                  debugPrint("  ⚡ [FINAL ALARM #$secondaryId] -> $formattedSubject on $dayKey at ${secondScheduledDate.hour.toString().padLeft(2, '0')}:${secondScheduledDate.minute.toString().padLeft(2, '0')} (${secondOffset}m warning)");
                } catch (e) {
                  // Ignore single failure
                }
              }
            }
          }
        }
      }

      debugPrint("────────────────────────────────────────────────────────────────");
      debugPrint("✅ TIMETABLE SCHEDULER FINISHED: $scheduledCount alarms scheduled.");
      debugPrint("════════════════════════════════════════════════════════════════");

      // Save debug log entry
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList('notification_debug_logs') ?? [];
      final logEntry = "${DateTime.now().toString().split('.')[0]}|Scheduled $scheduledCount alarms";
      logs.add(logEntry);
      if (logs.length > 50) logs.removeAt(0);
      await prefs.setStringList('notification_debug_logs', logs);

    } finally {
      _isSchedulingTimetable = false;
    }
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
