import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/notification_preferences.dart';
import '../../../../services/notification_service.dart';
import '../../../timetable/presentation/providers/timetable_provider.dart';
import '../../../../widgets/premium_touch_button.dart';

import '../../../../services/ad_service.dart';
import '../../../../widgets/ad_banner_widget.dart';
import '../../../../widgets/ad_native_widget.dart';
import '../../../../widgets/skeleton_loaders.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  final Color nirmaRed = const Color(0xFFC62828);
  final Color baseNavy = const Color(0xFF0F172A);
  final Color textGray = const Color(0xFF64748B);
  final Color borderGray = const Color(0xFFE2E8F0);
  final Color bgSurface = const Color(0xFFF1F4F9);

  TimetableNotificationSettings _settings = TimetableNotificationSettings.defaultSettings();
  bool _isLoading = true;
  TimetablePassStatus _passStatus = const TimetablePassStatus(
    isAdRequired: false,
    isUnlocked: true,
    remainingText: '',
  );

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final loaded = await TimetableNotificationSettings.loadFromPrefs();
    final passStatus = await AdService.getTimetablePassStatus();

    final isAdRequired = passStatus.isAdRequired;
    final isUnlocked = passStatus.isUnlocked;
    final effectiveActive = loaded.isEnabled && (!isAdRequired || isUnlocked);

    if (mounted) {
      setState(() {
        _settings = loaded;
        _passStatus = passStatus;
        _isLoading = false;
      });

      // If ad pass is required and expired, automatically show the rewarded ad unlock modal on open
      if (isAdRequired && !isUnlocked) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showRewardedUnlockModal();
          }
        });
      }
    }

    AdService.syncUserNotificationPassStatus(isEnabled: effectiveActive);
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

    final isAdRequired = _passStatus.isAdRequired;
    final isUnlocked = _passStatus.isUnlocked;
    final effectiveActive = newSettings.isEnabled && (!isAdRequired || isUnlocked);

    AdService.syncUserNotificationPassStatus(isEnabled: effectiveActive);
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
          : () {
              final isEnabled = _settings.isEnabled;
              final isAdRequired = _passStatus.isAdRequired;
              final isUnlocked = _passStatus.isUnlocked;
              final effectiveActive = isEnabled && (!isAdRequired || isUnlocked);

              return RefreshIndicator(
                onRefresh: _loadSettings,
                color: nirmaRed,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  children: [
                    // --- Master Switch Card ---
                    _buildMasterToggleCard(),
                    const SizedBox(height: 20),

                    // 🎨 Native Ad below Notification Reminder On/Off Section
                    const AdNativeCard(
                      placementKey: 'notifications_below_reminders',
                      isMediumTemplate: true,
                      margin: EdgeInsets.only(bottom: 20),
                    ),

                    if (!effectiveActive) ...[
                      _buildDisabledBanner(),
                      const SizedBox(height: 24),
                      if (isAdRequired && !isUnlocked) ...[
                        Center(
                          child: TextButton.icon(
                            onPressed: _showRewardedUnlockModal,
                            icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFDC2626), size: 22),
                            label: const Text(
                              'Watch Video to Activate Notifications',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFDC2626),
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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
                      const SizedBox(height: 24),

                      // --- Clean Banner Ad ---
                      const Center(child: AdBannerWidget(placementKey: 'notification_settings')),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              );
            }(),
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
    final isAdRequired = _passStatus.isAdRequired;
    final isUnlocked = _passStatus.isUnlocked;
    final effectiveActive = isEnabled && (!isAdRequired || isUnlocked);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: effectiveActive 
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
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: effectiveActive
                      ? nirmaRed.withValues(alpha: 0.1)
                      : borderGray.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  effectiveActive ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
                  color: effectiveActive ? nirmaRed : textGray,
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
                            color: effectiveActive
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : (isAdRequired && !isUnlocked
                                    ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                    : textGray.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            effectiveActive 
                                ? (isAdRequired && isUnlocked && _passStatus.remainingText.isNotEmpty 
                                    ? '⚡ ${_passStatus.remainingText}' 
                                    : 'ACTIVE') 
                                : (isAdRequired && !isUnlocked ? '⏳ EXPIRED' : '🔕 OFF'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: effectiveActive 
                                  ? const Color(0xFF059669) 
                                  : (isAdRequired && !isUnlocked ? const Color(0xFFDC2626) : textGray),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      effectiveActive
                          ? 'Timetable class alerts enabled'
                          : (isAdRequired && !isUnlocked
                              ? 'Pass expired. Watch video to activate'
                              : 'All timetable reminders are paused'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: effectiveActive ? const Color(0xFF059669) : (isAdRequired && !isUnlocked ? const Color(0xFFDC2626) : textGray),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CupertinoSwitch(
                value: effectiveActive,
                activeTrackColor: nirmaRed,
                onChanged: (val) async {
                  HapticFeedback.selectionClick();
                  if (!val) {
                    await _updateSettings(_settings.copyWith(isEnabled: false));
                  } else {
                    if (!isAdRequired) {
                      await _updateSettings(_settings.copyWith(isEnabled: true));
                    } else {
                      final status = await AdService.getTimetablePassStatus();
                      setState(() => _passStatus = status);
                      if (status.isUnlocked) {
                        await _updateSettings(_settings.copyWith(isEnabled: true));
                      } else {
                        _showRewardedUnlockModal();
                      }
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRewardedUnlockModal() {
    final passDays = AdService().timetablePassDays > 0 ? AdService().timetablePassDays : 3;
    final passHours = passDays * 24;
    final dayLabel = passDays == 1 ? 'Day' : 'Days';
    final dayLabelLower = passDays == 1 ? 'day' : 'days';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 25,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag handle
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Icon Badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFFF97316)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Unlock $passDays $dayLabel of Lecture Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.4,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              'Watch a quick 15-second sponsor video to activate all automatic timetable reminders and class notifications for $passDays full $dayLabelLower.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.45,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 20),

            // Benefits List
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  _buildBenefitRow('🔔 Smart first class of day reminder'),
                  const SizedBox(height: 8),
                  _buildBenefitRow('📚 Next class alerts before every lecture'),
                  const SizedBox(height: 8),
                  _buildBenefitRow('⚡ 100% automatic for the next $passHours hours'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Watch Video Button
            PremiumTouchButton(
              onTap: () async {
                Navigator.pop(ctx);
                await AdService().showRewardedAd(
                  context: context,
                  onRewardEarned: () async {
                    await AdService.grantTimetable3DayUnlock();
                    await _updateSettings(_settings.copyWith(isEnabled: true));
                    await _loadSettings();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                "🎉 $passDays-Day Notification Pass Activated!",
                                style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Manrope'),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF059669),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Watch Video & Unlock ($passDays $dayLabel)',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF10B981)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: 'Manrope',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisabledBanner() {
    final isAdRequired = _passStatus.isAdRequired;
    final isUnlocked = _passStatus.isUnlocked;
    final isExpired = isAdRequired && !isUnlocked;
    final passDays = AdService().timetablePassDays > 0 ? AdService().timetablePassDays : 3;
    final dayLabelLower = passDays == 1 ? 'day' : 'days';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired
              ? const Color(0xFFFECACA)
              : const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.alarm_off_rounded : Icons.info_outline_rounded,
            color: isExpired ? const Color(0xFFDC2626) : const Color(0xFFD97706),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isExpired
                  ? 'Notification Pass is expired. Turn the switch ON above or tap below to unlock $passDays $dayLabelLower of class reminders with a quick video.'
                  : 'Timetable reminders are turned off. Turn the switch ON above to set custom reminder times and activate alerts.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isExpired ? const Color(0xFF991B1B) : const Color(0xFF92400E),
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
              backgroundColor: baseNavy,
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
                backgroundColor: baseNavy,
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
