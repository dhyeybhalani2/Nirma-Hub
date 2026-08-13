import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

class ProvideFeedbackScreen extends ConsumerStatefulWidget {
  const ProvideFeedbackScreen({super.key});

  @override
  ConsumerState<ProvideFeedbackScreen> createState() => _ProvideFeedbackScreenState();
}

class _ProvideFeedbackScreenState extends ConsumerState<ProvideFeedbackScreen> {
  final Color nirmaNavy = const Color(0xFF1A2B48);
  final Color nirmaRed = const Color(0xFFC62828);
  final Color textDark = const Color(0xFF0F172A);
  final Color textGray = const Color(0xFF64748B);
  final Color borderGray = const Color(0xFFCBD5E1);
  final Color scaffoldBg = const Color(0xFFF1F4F9);

  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitFeedback() async {
    if (_rating == 0 && _feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.surface),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please provide a rating or some feedback before submitting.',
                  style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: nirmaRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userProfile = ref.read(authNotifierProvider).value;
      final userName = userProfile?.fullName ?? 'Anonymous';
      final userEmail = Supabase.instance.client.auth.currentUser?.email;

      await Supabase.instance.client.from('feedback').insert({
        'rating': _rating,
        'comment': _feedbackController.text.trim(),
        'user_email': userEmail,
        'user_name': userName,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.surface),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Thank you! Your feedback has been submitted successfully.',
                    style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: nirmaNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.surface),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to submit feedback. Please try again.',
                    style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: nirmaRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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
                  child: Icon(CupertinoIcons.arrow_left, color: Theme.of(context).colorScheme.onSurface, size: 18),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Provide Feedback',
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'We value your opinion',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  fontFamily: 'Manrope',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'How would you rate your experience with the app?',
                style: TextStyle(
                  fontSize: 15,
                  color: textGray,
                  fontFamily: 'Manrope',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              
              // Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    iconSize: 40,
                    icon: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: index < _rating ? const Color(0xFFFFB400) : borderGray,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  );
                }),
              ),

              SizedBox(height: 40),

              // Feedback Text Area
              Text(
                'Tell us more',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                  fontFamily: 'Manrope',
                ),
              ),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _feedbackController,
                  maxLines: 5,
                  style: TextStyle(
                    fontSize: 15,
                    color: textDark,
                    fontFamily: 'Manrope',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts or report an issue...',
                    hintStyle: TextStyle(color: textGray.withValues(alpha: 0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),

              SizedBox(height: 40),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: nirmaNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submitFeedback,
                child: _isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.surface, strokeWidth: 2),
                      )
                    : Text(
                        'Submit Feedback',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.surface,
                          fontFamily: 'Manrope',
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
