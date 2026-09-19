import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/notification_preferences.dart';
import '../../../../services/notification_service.dart';
import '../../../timetable/presentation/providers/timetable_provider.dart';
import '../../../../widgets/premium_touch_button.dart';

import '../../../../widgets/skeleton_loaders.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  Color get nirmaRed => context.c.accent;
  Color get baseNavy => context.c.text;
  Color get textGray => context.c.textMuted;
  Color get borderGray => context.c.border;
  Color get bgSurface => context.c.bg;

  TimetableNotificationSettings _settings = TimetableNotificationSettings.defaultSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final loaded = await TimetableNotificationSettings.loadFromPrefs();

    if (mounted) {
      setState(() {
        _settings = loaded;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSettings(TimetableNotificationSettings newSettings) async {
    final prefs = await SharedPreferences.getInstance();
    if (!newSettings.isEnabled) {
      await prefs.setBool('timetable_user_explicitly_muted', true);
    } else {
      await prefs.setBool('timetable_user_explicitly_muted', false);
    }

    setState(() {
      _settings = newSettings;
    });

    await newSettings.saveToPrefs();
    
    // Automatically apply to timetable
    final timetable = ref.read(timetableProvider);
    await NotificationService().scheduleTimetableNotifications(timetable, customSettings: newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSurface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
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
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Notification Settings',
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
      ),
      body: _isLoading
          ? const NotificationSettingsSkeleton()
          : RefreshIndicator(
              onRefresh: _loadSettings,
              color: nirmaRed,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  // --- Master Switch Card ---
                  _buildMasterToggleCard(),
                  const SizedBox(height: 20),

                  if (!_settings.isEnabled) ...[
                    _buildDisabledBanner(),
                    const SizedBox(height: 24),
                  ] else ...[
                    // --- First Class Settings Card ---
                    _buildSectionHeader('FIRST CLASS OF THE DAY'),
                    const SizedBox(height: 12),
                    _buildFirstClassCard(),
                    const SizedBox(height: 24),

                    // --- Subsequent Classes Settings Card ---
                    _buildSectionHeader('NEXT / SUBSEQUENT CLASSES'),
                    const SizedBox(height: 12),
                    _buildSubsequentClassCard(),
                    const SizedBox(height: 24),

                    // --- Alert & Vibration Card ---
                    _buildSectionHeader('ALERT PREFERENCES'),
                    const SizedBox(height: 12),
                    _buildAlertPreferencesCard(),
                    const SizedBox(height: 28),

                    // --- Action Buttons ---
                    _buildTestNotificationButton(),
                    const SizedBox(height: 12),
                    _buildResetDefaultsButton(),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: textGray,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildMasterToggleCard() {
    final isEnabled = _settings.isEnabled;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEnabled 
              ? const Color(0xFF10B981).withValues(alpha: 0.3) 
              : borderGray,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEnabled
                  ? nirmaRed.withValues(alpha: 0.1)
                  : borderGray.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
              color: isEnabled ? nirmaRed : textGray,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Timetable Reminders',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: baseNavy,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : textGray.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isEnabled ? 'ACTIVE' : '🔕 OFF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isEnabled 
                              ? context.c.pick(const Color(0xFF059669), const Color(0xFF34D399)) 
                              : textGray,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isEnabled
                      ? 'Timetable class alerts enabled'
                      : 'All timetable reminders are paused',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? context.c.pick(const Color(0xFF059669), const Color(0xFF34D399)) : textGray,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoSwitch(
            value: isEnabled,
            activeTrackColor: nirmaRed,
            onChanged: (val) async {
              HapticFeedback.selectionClick();
              await _updateSettings(_settings.copyWith(isEnabled: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: context.c.pick(const Color(0xFFD97706), const Color(0xFFFBBF24)),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Timetable reminders are turned off. Turn the switch ON above to set custom reminder times and activate alerts.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.c.pick(const Color(0xFF92400E), const Color(0xFFFCD34D)),
                fontFamily: 'Inter',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstClassCard() {
    final r1 = _settings.firstClassReminder1Minutes;
    final r2Enabled = _settings.firstClassReminder2Enabled;
    final r2 = _settings.firstClassReminder2Minutes;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGray),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Primary Reminder (1st Alert)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: baseNavy,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How many minutes before the day\'s first class:',
            style: TextStyle(fontSize: 12, color: textGray),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [10, 15, 20, 30, 45, 60].map((mins) {
              final isSelected = (r1 == mins);
              return _buildTimingChip(
                label: mins == 20 ? '$mins min (Default)' : '$mins min',
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _updateSettings(_settings.copyWith(firstClassReminder1Minutes: mins));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Divider(color: borderGray.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 16),

          // Secondary Reminder Toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secondary Reminder (2nd Alert)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: baseNavy,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Optional final prompt right before start',
                      style: TextStyle(fontSize: 12, color: textGray),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CupertinoSwitch(
                value: r2Enabled,
                activeTrackColor: nirmaRed,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  _updateSettings(_settings.copyWith(firstClassReminder2Enabled: val));
                },
              ),
            ],
          ),

          if (r2Enabled) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [5, 10, 15].where((m) => m < r1).map((mins) {
                final isSelected = (r2 == mins);
                return _buildTimingChip(
                  label: '$mins min before',
                  isSelected: isSelected,
                  accentColor: nirmaRed,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _updateSettings(_settings.copyWith(firstClassReminder2Minutes: mins));
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubsequentClassCard() {
    final usePrev = _settings.subsequentUsePreviousEnd;
    final r1 = _settings.subsequentReminder1Minutes;
    final r2Enabled = _settings.subsequentReminder2Enabled;
    final r2 = _settings.subsequentReminder2Minutes;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGray),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Primary Reminder Style',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: baseNavy,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 12),
          
          // Style 1: 10m before previous class ends (Default)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.selectionClick();
              _updateSettings(_settings.copyWith(subsequentUsePreviousEnd: true));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: usePrev
                    ? nirmaRed.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: usePrev ? nirmaRed : borderGray,
                  width: usePrev ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    usePrev ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: usePrev ? nirmaRed : textGray,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '10 mins before previous class ends (Smart)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: baseNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gives you advance notice during your ongoing lecture',
                          style: TextStyle(fontSize: 11, color: textGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Style 2: Fixed minutes before class starts
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.selectionClick();
              _updateSettings(_settings.copyWith(subsequentUsePreviousEnd: false));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: !usePrev
                    ? nirmaRed.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !usePrev ? nirmaRed : borderGray,
                  width: !usePrev ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    !usePrev ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: !usePrev ? nirmaRed : textGray,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fixed minutes before class starts',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: baseNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Custom fixed lead time before each lecture',
                          style: TextStyle(fontSize: 11, color: textGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!usePrev) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [5, 10, 15, 20].map((mins) {
                final isSelected = (r1 == mins);
                return _buildTimingChip(
                  label: '$mins min before',
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _updateSettings(_settings.copyWith(subsequentReminder1Minutes: mins));
                  },
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 18),
          Divider(color: borderGray.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 16),

          // Secondary Reminder for Subsequent Classes
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secondary Reminder (2nd Alert)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: baseNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Optional final prompt before next class',
                      style: TextStyle(fontSize: 12, color: textGray),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CupertinoSwitch(
                value: r2Enabled,
                activeTrackColor: nirmaRed,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  _updateSettings(_settings.copyWith(subsequentReminder2Enabled: val));
                },
              ),
            ],
          ),

          if (r2Enabled) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [5, 10].map((mins) {
                final isSelected = (r2 == mins);
                return _buildTimingChip(
                  label: '$mins min before',
                  isSelected: isSelected,
                  accentColor: nirmaRed,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _updateSettings(_settings.copyWith(subsequentReminder2Minutes: mins));
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertPreferencesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGray),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: nirmaRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.vibration_rounded, color: nirmaRed, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vibration',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: baseNavy,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vibrate phone when class reminder triggers',
                  style: TextStyle(fontSize: 12, color: textGray),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoSwitch(
            value: _settings.enableVibration,
            activeTrackColor: nirmaRed,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              _updateSettings(_settings.copyWith(enableVibration: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimingChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    final color = accentColor ?? nirmaRed;
    return PremiumTouchButton(
      enableRipple: false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : borderGray,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : baseNavy,
            fontFamily: 'Manrope',
          ),
        ),
      ),
    );
  }

  Widget _buildTestNotificationButton() {
    return PremiumTouchButton(
      enableRipple: false,
      onTap: () async {
        if (_settings.enableVibration) {
          HapticFeedback.heavyImpact();
        }
        await NotificationService().sendTestNotification(_settings);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Test reminder sent to your notification tray!',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: context.c.hero,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: nirmaRed.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline_rounded, color: nirmaRed, size: 20),
            const SizedBox(width: 8),
            Text(
              'Send Test Notification Preview',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: nirmaRed,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetDefaultsButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          HapticFeedback.mediumImpact();
          final defaults = TimetableNotificationSettings.defaultSettings();
          await _updateSettings(defaults);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Reset to default notification settings.'),
                backgroundColor: context.c.hero,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        icon: Icon(Icons.restore_rounded, size: 16, color: textGray),
        label: Text(
          'Reset to Default Settings',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textGray,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
