import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/timetable_provider.dart';
import '../../domain/timetable_entry.dart';
import '../../../../home_screen.dart';

class FullTimetableScreen extends ConsumerStatefulWidget {
  const FullTimetableScreen({super.key});

  @override
  ConsumerState<FullTimetableScreen> createState() => _FullTimetableScreenState();
}

class _FullTimetableScreenState extends ConsumerState<FullTimetableScreen> {
  final Color nirmaRed = const Color(0xFFC62828);
  final Color textGray = const Color(0xFF64748B);
  final Color baseNavy = const Color(0xFF0F172A);
  final Color borderGray = const Color(0xFFE2E8F0);
  final Color bgSurface = const Color(0xFFF1F4F9); // Slate 100

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

  Widget _buildFreeLectureRow(String startTime, String endTime, {String label = "Free Lecture"}) {
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
                Text(startTime, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textGray.withValues(alpha: 0.5))),
              ]
            )
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
                Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textGray.withValues(alpha: 0.6))),
                SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableRow(String time, String endTimeStr, String title, String prof, String location, bool isActiveDay, DateTime now) {
    final currentMins = now.hour * 60 + now.minute;
    final startMins = _timeToMinutes(time);
    final endMins = _timeToMinutes(endTimeStr); 

    Color lineColor = nirmaRed;
    Color timeColor = textGray;
    Color locationColor = nirmaRed;
    IconData? stateIcon;
    Color? stateIconColor;

    if (isActiveDay) {
      if (currentMins >= endMins) {
        lineColor = const Color(0xFF10B981); // Green (Past)
        locationColor = const Color(0xFF10B981);
        timeColor = const Color(0xFF10B981);
        stateIcon = CupertinoIcons.checkmark_seal_fill;
        stateIconColor = const Color(0xFF10B981);
      } else if (currentMins >= startMins && currentMins < endMins) {
        lineColor = const Color(0xFFF59E0B); // Yellow (Current)
        locationColor = const Color(0xFF10B981);
        timeColor = const Color(0xFFF59E0B);
        stateIcon = Icons.radio_button_checked;
        stateIconColor = const Color(0xFFF59E0B);
      } else {
        lineColor = nirmaRed;
        locationColor = nirmaRed;
        timeColor = textGray;
        stateIcon = null;
      }
    } else {
      lineColor = nirmaRed;
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
                Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: timeColor)),
                if (stateIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Icon(stateIcon, color: stateIconColor, size: 14), 
                  )
              ]
            )
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
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: baseNavy)),
                SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.person_solid, size: 12, color: textGray.withValues(alpha: 0.6)),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(prof, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textGray.withValues(alpha: 0.8)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text("|", style: TextStyle(fontSize: 13, color: textGray.withValues(alpha: 0.3), fontWeight: FontWeight.w600)),
                    ),
                    Icon(CupertinoIcons.location_solid, size: 12, color: locationColor.withValues(alpha: 0.8)),
                    SizedBox(width: 4),
                    Text(location, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: locationColor)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDayTab(String day, List<TimetableEntry> timetable, bool isActiveDay, DateTime now) {
    final targetLectures = timetable.where((t) => t.day == day).toList();
    targetLectures.sort((a, b) => _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)));

    if (targetLectures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.calendar_today, size: 48, color: borderGray),
            SizedBox(height: 16),
            Text("No classes scheduled for $day! 🎉", 
              style: TextStyle(color: textGray, fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      );
    }

    Set<String> morningDays = {};
    for (var lecture in timetable) {
      if (_timeToMinutes(lecture.startTime) < 700) {
        morningDays.add(lecture.day);
      }
    }
    bool isMorningShift = morningDays.length > 1;
    final mainStartTime = isMorningShift ? "07:45 AM" : "11:40 AM";
    final mainEndTime = isMorningShift ? "02:25 PM" : "06:20 PM";

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      physics: const BouncingScrollPhysics(),
      itemCount: targetLectures.length,
      itemBuilder: (context, index) {
        final lecture = targetLectures[index];
        
        Widget freeLectureWidget = SizedBox.shrink();
        Widget endFreeLectureWidget = SizedBox.shrink();

        String getGapLabel(String startStr, String endStr) {
          int s = _timeToMinutes(startStr);
          int e = _timeToMinutes(endStr);
          if (isMorningShift) {
            if (s <= 700 && e >= 755) return "Lunch Break";
          } else {
            if (s <= 810 && e >= 865) return "Lunch Break";
          }
          return "Free Lecture";
        }

        if (index == 0) {
          if (_timeToMinutes(lecture.startTime) > _timeToMinutes(mainStartTime)) {
            freeLectureWidget = Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildFreeLectureRow(mainStartTime, lecture.startTime, label: getGapLabel(mainStartTime, lecture.startTime)),
            );
          }
        } else {
          final prev = targetLectures[index-1];
          final gap = _timeToMinutes(lecture.startTime) - _timeToMinutes(prev.endTime);
          if (gap > 15) {
            freeLectureWidget = Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildFreeLectureRow(prev.endTime, lecture.startTime, label: getGapLabel(prev.endTime, lecture.startTime)),
            );
          }
        }

        if (index == targetLectures.length - 1) {
          if (_timeToMinutes(lecture.endTime) < _timeToMinutes(mainEndTime)) {
            endFreeLectureWidget = Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildFreeLectureRow(lecture.endTime, mainEndTime, label: getGapLabel(lecture.endTime, mainEndTime)),
            );
          }
        }
        
        return Column(
          children: [
            freeLectureWidget,
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildTimetableRow(
                lecture.startTime, 
                lecture.endTime,
                lecture.subject, 
                lecture.professor, 
                lecture.location, 
                isActiveDay,
                now
              ),
            ),
            endFreeLectureWidget,
          ]
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final timetable = ref.watch(timetableProvider);
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
    
    int currentWeekday = DateTime.now().weekday;
    int initialIndex = 0;
    if (currentWeekday >= 1 && currentWeekday <= 5) {
      initialIndex = currentWeekday - 1;
    }

    return DefaultTabController(
      length: days.length,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: bgSurface,
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
            'Full Timetable',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: baseNavy,
              letterSpacing: -0.5,
              fontFamily: 'Manrope',
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderGray, width: 1)),
              ),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: nirmaRed,
                unselectedLabelColor: textGray,
                labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'Manrope'),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Manrope'),
                indicatorColor: nirmaRed,
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                tabs: days.map((day) => Tab(text: day)).toList(),
              ),
            ),
          ),
        ),
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: days.map((day) {
            bool isActiveDay = false;
            if (currentWeekday >= 1 && currentWeekday <= 5) {
              isActiveDay = (day == days[currentWeekday - 1]);
            }
            return _KeepAlivePage(
              child: _buildDayTab(day, timetable, isActiveDay, ref.watch(clockProvider).value ?? DateTime.now()),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
