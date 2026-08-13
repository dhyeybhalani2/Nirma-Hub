import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'widgets/premium_touch_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/coding/data/coding_service.dart';
import 'features/coding/domain/coding_profile_model.dart';
import 'help_center_screen.dart';
import 'provide_feedback_screen.dart';

IconData _getBranchIcon(String branchName) {
  switch (branchName) {
    case 'Computer Science Engineering': return Icons.computer_outlined;
    case 'AI & ML': return Icons.psychology_outlined;
    case 'Electronics and Communication Engineering': return Icons.sensors_outlined;
    case 'Electrical Engineering': return Icons.bolt_outlined;
    case 'Electronics and Instrumentation Engineering': return CupertinoIcons.gauge;
    case 'Electronics Engineering (VLSI Design and Semiconductor Technology)': return Icons.memory_outlined;
    case 'Mechanical Engineering': return Icons.precision_manufacturing_outlined;
    case 'Chemical Engineering': return Icons.science_outlined;
    case 'Civil Engineering': return Icons.architecture_outlined;
    default: return Icons.school_outlined;
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _currentNavIndex = 3;
  CodingProfile? _codingProfile;
  bool _isLoadingCodingProfile = true;
  bool _isUploadingProfilePic = false;

  void _showProfilePicOptions(bool hasProfileImage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
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
                    CupertinoIcons.person_solid,
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
                        'Profile Photo',
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
            SizedBox(height: 24),
            
            // Change Photo Option
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  splashColor: const Color(0xFFE5202B).withValues(alpha: 0.1),
                  highlightColor: const Color(0xFFE5202B).withValues(alpha: 0.05),
                  onTap: () {
                    Future.delayed(const Duration(milliseconds: 120), () {
                      Navigator.pop(context);
                      _updateProfilePicture();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5202B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(CupertinoIcons.camera_fill, color: Color(0xFFE5202B)),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Change Photo',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Remove Photo Option (Only if currently has a photo)
            if (hasProfileImage) ...[
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    splashColor: const Color(0xFFE5202B).withValues(alpha: 0.1),
                    highlightColor: const Color(0xFFE5202B).withValues(alpha: 0.05),
                    onTap: () async {
                      Future.delayed(const Duration(milliseconds: 120), () async {
                        Navigator.pop(context);
                        setState(() {
                          _isUploadingProfilePic = true;
                        });
                        try {
                          final authNotifier = ref.read(authNotifierProvider.notifier);
                          await authNotifier.updateProfile(profileImageUrl: '');
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to remove profile picture: ')),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isUploadingProfilePic = false;
                            });
                          }
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(CupertinoIcons.trash_fill, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Remove Photo',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return; // User canceled

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: const Color(0xFF0F172A),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            cropStyle: CropStyle.circle,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            cropStyle: CropStyle.circle,
          ),
        ],
      );

      if (croppedFile == null) return; // User canceled crop

      setState(() {
        _isUploadingProfilePic = true;
      });

      final authNotifier = ref.read(authNotifierProvider.notifier);
      final newUrl = await authNotifier.uploadProfileImage(File(croppedFile.path));
      
      if (newUrl != null) {
        await authNotifier.updateProfile(profileImageUrl: newUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingProfilePic = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCodingProfile();
  }

  Future<void> _fetchCodingProfile() async {
    final profile = await CodingService().getCurrentCodingProfile();
    if (mounted) {
      setState(() {
        _codingProfile = profile;
        _isLoadingCodingProfile = false;
      });
    }
  }

  // Theme Colors
  final Color nirmaNavy = const Color(0xFF1A2B48);
  final Color nirmaRed = const Color(0xFFC62828);
  final Color textDark = const Color(0xFF0F172A);
  final Color textGray = const Color(0xFF64748B);
  final Color borderGray = const Color(0xFFCBD5E1);
  final Color scaffoldBg = const Color(0xFFF1F4F9);

  @override
  Widget build(BuildContext context) {
    const double paddingMobile = 24.0;
    final authState = ref.watch(authNotifierProvider);
    final userProfile = authState.value;

    if (userProfile == null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          title: Text(
            "Profile",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
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
                child: PremiumTouchButton(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, _, __) => const HomePage(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    }
                  },
                  enableRipple: false,
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
          ),
        ),
        body: const _ProfileSkeleton(),
      );
    }
    
    String _userName = userProfile.fullName;
    String _rollNo = userProfile.rollNo;
    String _academicYear = userProfile.academicYear;
    String _branch = userProfile.branch;
    String _division = userProfile.division;
    String _batch = userProfile.batch;
    String? _profileImageUrl = userProfile.profileImageUrl;
    String _email = Supabase.instance.client.auth.currentUser?.email ?? '${_rollNo.toLowerCase()}@nirmauni.ac.in';

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
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
              child: PremiumTouchButton(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, _, __) => const HomePage(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  }
                },
                enableRipple: false,
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: paddingMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16),

              // User Info Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _isUploadingProfilePic ? null : () => _showProfilePicOptions(_profileImageUrl != null && _profileImageUrl!.isNotEmpty),
                      child: Stack(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                              border: Border.all(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                              image: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(_profileImageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                                ? Center(
                                    child: _userName.isEmpty
                                        ? Icon(
                                            CupertinoIcons.person_solid,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant, // Slate 400
                                            size: 40,
                                          )
                                        : Text(
                                            () {
                                              final parts = _userName.trim().split(RegExp(r'\s+'));
                                              if (parts.length > 1) return parts[1][0].toUpperCase();
                                              return parts[0][0].toUpperCase();
                                            }(),
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.surface,
                                              fontSize: 32,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'Manrope',
                                            ),
                                          ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF1E293B), width: 2),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 12,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            ),
                          ),
                          if (_isUploadingProfilePic)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.surface,
                              fontFamily: 'Manrope',
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            _email,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                              fontFamily: 'Inter',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 16),
                          PremiumTouchButton(
                            onTap: () {
                              _showEditProfileSheet(
                                context,
                                initialName: _userName,
                                initialRollNo: _rollNo,
                                initialBranch: _branch,
                                initialYear: _academicYear,
                                initialDivision: _division,
                                initialBatch: _batch,
                              );
                            },
                            enableRipple: true,
                            borderRadius: BorderRadius.circular(20),
                            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                            splashColor: Colors.white.withValues(alpha: 0.2),
                            highlightColor: Colors.white.withValues(alpha: 0.1),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.15)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.surface, size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.surface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // ACADEMIC DETAILS Header
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'ACADEMIC DETAILS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: textGray,
                    fontFamily: 'Inter',
                  ),
                ),
              ),

              // Academic Details Card
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.badge_outlined,
                      label: 'Roll Number',
                      value: _rollNo,
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: _getBranchIcon(_branch),
                      label: 'Branch',
                      value: _branch,
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Academic Year',
                      value: _academicYear,
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.groups_outlined,
                      label: 'Batch',
                      value: _batch,
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.book_outlined,
                      label: 'Division',
                      value: _division,
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.code_outlined,
                      label: 'LeetCode',
                      value: _isLoadingCodingProfile ? 'Loading...' : (_codingProfile?.leetcodeUsername ?? 'Not linked'),
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.bar_chart_outlined,
                      label: 'Codeforces',
                      value: _isLoadingCodingProfile ? 'Loading...' : (_codingProfile?.codeforcesUsername ?? 'Not linked'),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // SUPPORT Header
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'SUPPORT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: textGray,
                    fontFamily: 'Inter',
                  ),
                ),
              ),

              // Support Card
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.help_outline_rounded,
                      label: 'Help Center',
                      value: '',
                      isAction: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.feedback_outlined,
                      label: 'Provide Feedback',
                      value: '',
                      isAction: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProvideFeedbackScreen()),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      value: '',
                      isAction: true,
                      onTap: () async {
                        final Uri url = Uri.parse('https://www.nirma-hub.online/privacy-policy.html');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not open Privacy Policy link')),
                            );
                          }
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.gavel_outlined,
                      label: 'Terms of Service',
                      value: '',
                      isAction: true,
                      onTap: () async {
                        final Uri url = Uri.parse('https://www.nirma-hub.online/terms.html');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not open Terms of Service link')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Logout Action Section
              PremiumTouchButton(
                enableRipple: false,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: nirmaRed.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: nirmaRed,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        _showConfirmationBottomSheet(
                          context: context,
                          title: 'Confirm Logout',
                          description: 'Are you sure you want to logout? You will need to sign in again to access your profile.',
                          confirmText: 'Logout',
                          confirmColor: nirmaRed,
                          icon: Icons.logout_rounded,
                          onConfirm: () {
                            ref.read(authNotifierProvider.notifier).signOut();
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                        );
                      },
                      splashColor: Colors.white.withValues(alpha: 0.2),
                      highlightColor: Colors.white.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: Theme.of(context).colorScheme.surface, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.surface,
                                fontFamily: 'Inter',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Delete Account Section
              PremiumTouchButton(
                enableRipple: false,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: nirmaRed.withValues(alpha: 0.5), width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        _showConfirmationBottomSheet(
                          context: context,
                          title: 'Delete Account',
                          description: 'Are you absolutely sure you want to permanently delete your account? All your notes, profiles, and tickets will be lost. This action cannot be undone.',
                          confirmText: 'Delete',
                          confirmColor: nirmaRed,
                          icon: Icons.delete_outline_rounded,
                          onConfirm: () async {
                            final navigator = Navigator.of(context, rootNavigator: true);
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => Center(
                                child: CircularProgressIndicator(color: Theme.of(context).colorScheme.surface),
                              ),
                            );

                            try {
                              await Supabase.instance.client.rpc('delete_user_account');
                              navigator.pop(); // Dismiss loading
                              
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Account permanently deleted.'),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                ),
                              );

                              ref.read(authNotifierProvider.notifier).signOut();
                              navigator.popUntil((route) => route.isFirst);
                            } catch (e) {
                              navigator.pop();
                              scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text('Failed to delete account: $e')),
                              );
                            }
                          },
                        );
                      },
                      splashColor: nirmaRed.withValues(alpha: 0.1),
                      highlightColor: nirmaRed.withValues(alpha: 0.05),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline_rounded, color: nirmaRed, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Delete Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: nirmaRed,
                                fontFamily: 'Inter',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 64, right: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: borderGray.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isAction = false,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final effectiveIconColor = iconColor ?? nirmaRed;
    return PremiumTouchButton(
      onTap: isAction ? (onTap ?? () {}) : null,
      enableRipple: true,
      splashColor: effectiveIconColor.withValues(alpha: 0.1),
      highlightColor: effectiveIconColor.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: effectiveIconColor.withValues(alpha: 0.9), size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isAction) ...[
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textGray,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                        fontFamily: 'Inter',
                        height: 1.3,
                      ),
                    ),
                  ] else ...[
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textDark, // Changed from effectiveIconColor
                        fontFamily: 'Inter',
                      ),
                    ),
                  ]
                ],
              ),
            ),
            if (isAction)
              Icon(Icons.chevron_right_rounded, color: borderGray, size: 24),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(
    BuildContext context, {
    required String initialName,
    required String initialRollNo,
    required String initialBranch,
    required String initialYear,
    required String initialDivision,
    required String initialBatch,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileSheet(
        initialName: initialName,
        initialRollNo: initialRollNo,
        initialBranch: initialBranch,
        initialYear: initialYear,
        initialDivision: initialDivision,
        initialBatch: initialBatch,
      ),
    );
  }
  void _showConfirmationBottomSheet({
    required BuildContext context,
    required String title,
    required String description,
    required String confirmText,
    required Color confirmColor,
    required IconData icon,
    required VoidCallback onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
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
        child: SafeArea(
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
                      color: confirmColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: confirmColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
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
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: PremiumTouchButton(
                      enableRipple: false,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Material(
                          color: Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            splashColor: const Color(0xFF64748B).withValues(alpha: 0.1),
                            highlightColor: const Color(0xFF64748B).withValues(alpha: 0.05),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: PremiumTouchButton(
                      enableRipple: false,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: confirmColor.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: confirmColor,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              Navigator.of(context).pop();
                              onConfirm();
                            },
                            splashColor: Colors.white.withValues(alpha: 0.2),
                            highlightColor: Colors.white.withValues(alpha: 0.1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              child: Text(
                                confirmText,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.surface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final String initialName;
  final String initialRollNo;
  final String initialBranch;
  final String initialYear;
  final String initialDivision;
  final String initialBatch;

  const _EditProfileSheet({
    required this.initialName,
    required this.initialRollNo,
    required this.initialBranch,
    required this.initialYear,
    required this.initialDivision,
    required this.initialBatch,
  });

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _rollController;
  late final TextEditingController _divisionController;
  late final TextEditingController _batchController;

  late String _selectedYear;
  late String _selectedBranch;

  String? _nameError;
  String? _rollError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _rollController = TextEditingController(text: widget.initialRollNo);
    _divisionController = TextEditingController(text: widget.initialDivision);
    _batchController = TextEditingController(text: widget.initialBatch);
    
    _selectedYear = widget.initialYear;
    _selectedBranch = widget.initialBranch;

    _divisionController.addListener(_onDivisionChanged);
  }

  @override
  void dispose() {
    _divisionController.removeListener(_onDivisionChanged);
    _nameController.dispose();
    _rollController.dispose();
    _divisionController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  void _onDivisionChanged() {
    final divText = _divisionController.text.toUpperCase();
    final batchText = _batchController.text.toUpperCase();
    
    if (divText.isNotEmpty) {
      if (batchText.isNotEmpty) {
        if (batchText[0] != divText[0]) {
          _batchController.text = divText[0] + (batchText.length > 1 ? batchText.substring(1) : '');
        }
      } else {
        _batchController.text = divText[0];
      }
    }
  }

  final Color nirmaNavy = const Color(0xFF1A2B48);
  final Color nirmaRed = const Color(0xFFC62828);
  final Color textDark = const Color(0xFF0F172A);
  final Color textGray = const Color(0xFF64748B);
  final Color borderGray = const Color(0xFFCBD5E1);
  final Color inputFill = const Color(0xFFF8FAFC);
  final Color scaffoldBg = const Color(0xFFF1F4F9);


  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 10, // Match action bottom sheet padding
        bottom: bottomInset > 0 ? bottomInset + 24 : MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
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
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5202B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Color(0xFFE5202B),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                PremiumTouchButton(
                  onTap: () => Navigator.pop(context),
                  enableRipple: false,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface, size: 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildLabel('Full Name'),
            _buildTextField(
              controller: _nameController,
              hint: 'Full Name',
              prefixIcon: Icons.person_outline_rounded,
              errorText: _nameError,
            ),
            SizedBox(height: 12),
            _buildLabel('Roll No.'),
            _buildTextField(
              controller: _rollController,
              hint: 'E.g. 25BCE000',
              prefixIcon: Icons.badge_outlined,
              errorText: _rollError,
              inputFormatters: [
                _RollNoFormatter(),
              ],
            ),
            SizedBox(height: 12),
            _buildSelectorField(
              label: 'Branch',
              value: _selectedBranch,
              prefixIcon: _getBranchIcon(_selectedBranch),
              onTap: () => _showBranchSelector(context),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Division'),
                      _buildTextField(
                        controller: _divisionController,
                        hint: 'E.g. A',
                        prefixIcon: Icons.book_outlined,
                        inputFormatters: [
                          _DivisionFormatter(),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Batch'),
                      _buildTextField(
                        controller: _batchController,
                        hint: 'E.g. A3',
                        prefixIcon: Icons.groups_outlined,
                        inputFormatters: [
                          _BatchFormatter(_divisionController),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildLabel('Academic Year'),
            _buildFixedChipGroup(
              items: ['1st', '2nd', '3rd', '4th'],
              selected: _selectedYear,
              onSelect: (val) {
                setState(() => _selectedYear = val);
              },
            ),
            SizedBox(height: 24),
            PremiumTouchButton(
              onTap: () {
                setState(() {
                  _nameError = _nameController.text.trim().isEmpty ? 'Name cannot be empty' : null;
                  _rollError = _rollController.text.trim().isEmpty ? 'Roll No cannot be empty' : null;
                });

                if (_nameError != null || _rollError != null) {
                  return;
                }
                
                ref.read(authNotifierProvider.notifier).updateProfile(
                  fullName: _nameController.text.trim(),
                  academicYear: _selectedYear,
                  division: _divisionController.text.trim(),
                  batch: _batchController.text.trim(),
                  branch: _selectedBranch,
                  rollNo: _rollController.text.trim(),
                );
                Navigator.pop(context);
              },
              enableRipple: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: nirmaNavy,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: nirmaNavy.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.surface,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textDark,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: textDark,
        fontFamily: 'Inter',
      ),
      cursorColor: nirmaRed,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        errorText: errorText,
        hintStyle: TextStyle(
          color: textGray.withValues(alpha: 0.6),
          fontSize: 14,
          fontFamily: 'Inter',
        ),
        filled: true,
        fillColor: inputFill,
        prefixIcon: Icon(prefixIcon, color: textGray.withValues(alpha: 0.8), size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: BorderSide(color: nirmaRed, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: nirmaRed, width: 1.8),
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
            child: PremiumTouchButton(
              onTap: () => onSelect(item),
              enableRipple: false,
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
                      fontFamily: 'Inter',
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

  Widget _buildSelectorField({
    required String label,
    required String value,
    required IconData prefixIcon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        PremiumTouchButton(
          onTap: onTap,
          enableRipple: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: inputFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderGray.withValues(alpha: 0.6), width: 1.2),
            ),
            child: Row(
              children: [
                Icon(prefixIcon, color: textGray.withValues(alpha: 0.8), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textDark,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: textGray, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showBranchSelector(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.65,
        child: _BranchSelectorSheet(currentBranch: _selectedBranch),
      ),
    );
    if (result != null) {
      setState(() => _selectedBranch = result);
    }
  }
}

class _BranchSelectorSheet extends StatefulWidget {
  final String currentBranch;
  const _BranchSelectorSheet({required this.currentBranch});

  @override
  State<_BranchSelectorSheet> createState() => _BranchSelectorSheetState();
}

class _BranchSelectorSheetState extends State<_BranchSelectorSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allBranches = [
    {'name': 'Computer Science Engineering', 'icon': Icons.computer_outlined},
    {'name': 'AI & ML', 'icon': Icons.psychology_outlined},
    {'name': 'Electronics and Communication Engineering', 'icon': Icons.sensors_outlined},
    {'name': 'Electrical Engineering', 'icon': Icons.bolt_outlined},
    {'name': 'Electronics and Instrumentation Engineering', 'icon': CupertinoIcons.gauge},
    {'name': 'Electronics Engineering (VLSI Design and Semiconductor Technology)', 'icon': Icons.memory_outlined},
    {'name': 'Mechanical Engineering', 'icon': Icons.precision_manufacturing_outlined},
    {'name': 'Chemical Engineering', 'icon': Icons.science_outlined},
    {'name': 'Civil Engineering', 'icon': Icons.architecture_outlined},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBranches = _allBranches.where((b) =>
      b['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Branch',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'Inter',
                  ),
                ),
                PremiumTouchButton(
                  onTap: () => Navigator.pop(context),
                  enableRipple: false,
                  child: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 24),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 15,
                  fontFamily: 'Inter',
                ),
                prefixIcon: Icon(CupertinoIcons.search, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.8),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.surfaceContainer),
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredBranches.length,
              itemBuilder: (context, index) {
                final branch = filteredBranches[index];
                final isSelected = branch['name'] == widget.currentBranch;
                final nirmaRed = const Color(0xFFC62828);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? nirmaRed.withValues(alpha: 0.1) : const Color(0xFFF1F4F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(branch['icon'], color: isSelected ? nirmaRed : const Color(0xFF64748B), size: 20),
                  ),
                  title: Text(
                    branch['name'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface, // Keep text dark/black as in screenshot
                      fontFamily: 'Inter',
                    ),
                  ),
                  trailing: isSelected 
                      ? Icon(Icons.check_circle, color: nirmaRed, size: 22)
                      : null,
                  onTap: () {
                    Navigator.pop(context, branch['name']);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RollNoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.toUpperCase();
    String newText = '';
    
    for (int i = 0; i < text.length; i++) {
      if (newText.length >= 8) break;
      
      String char = text[i];
      if (newText.length < 2) {
        // Must be digit
        if (RegExp(r'[0-9]').hasMatch(char)) {
          newText += char;
        }
      } else if (newText.length < 5) {
        // Must be alphabet
        if (RegExp(r'[A-Z]').hasMatch(char)) {
          newText += char;
        }
      } else if (newText.length < 8) {
        // Must be digit
        if (RegExp(r'[0-9]').hasMatch(char)) {
          newText += char;
        }
      }
    }
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class _DivisionFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.toUpperCase();
    String newText = '';
    for (int i = 0; i < text.length; i++) {
      if (RegExp(r'[A-Z]').hasMatch(text[i])) {
        newText = text[i];
        break;
      }
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class _BatchFormatter extends TextInputFormatter {
  final TextEditingController divisionController;
  
  _BatchFormatter(this.divisionController);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.toUpperCase();
    String newText = '';
    
    String division = divisionController.text.toUpperCase();
    String requiredFirstChar = division.isNotEmpty ? division[0] : '';

    for (int i = 0; i < text.length; i++) {
      if (newText.length >= 2) break; // Max 2 chars
      
      String char = text[i];
      if (newText.length == 0) {
        if (requiredFirstChar.isNotEmpty) {
          if (char == requiredFirstChar) {
            newText += char;
          }
        } else {
          if (RegExp(r'[A-Z]').hasMatch(char)) {
            newText += char;
          }
        }
      } else if (newText.length == 1) {
        if (RegExp(r'[0-9]').hasMatch(char)) {
          newText += char;
        }
      }
    }
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class _ProfileSkeleton extends StatefulWidget {
  const _ProfileSkeleton();

  @override
  State<_ProfileSkeleton> createState() => _ProfileSkeletonState();
}

class _ProfileSkeletonState extends State<_ProfileSkeleton> with SingleTickerProviderStateMixin {
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 16),
                // User Info Card Skeleton
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2B48), // nirmaNavy
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 18,
                              width: 150,
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 13,
                              width: 180,
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            ),
                            SizedBox(height: 16),
                            Container(
                              height: 36,
                              width: 100,
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                
                // Academic Details Header Skeleton
                Container(
                  height: 14,
                  width: 120,
                  margin: const EdgeInsets.only(left: 4, bottom: 12, right: 200),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(4)),
                ),
                
                // Academic Details Card Skeleton
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: List.generate(5, (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Container(width: 24, height: 24, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, shape: BoxShape.circle)),
                          SizedBox(width: 16),
                          Container(width: 100, height: 14, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(4))),
                          Spacer(),
                          Container(width: 80, height: 14, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(4))),
                        ],
                      ),
                    )),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
