import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  final Color nirmaNavy = const Color(0xFF1A2B48);
  final Color nirmaRed = const Color(0xFFC62828);
  final Color textDark = const Color(0xFF0F172A);
  final Color textGray = const Color(0xFF64748B);
  final Color borderGray = const Color(0xFFCBD5E1);
  final Color scaffoldBg = const Color(0xFFF1F4F9);

  final List<Map<String, String>> faqs = [
    {
      'question': 'How do I link my LeetCode or Codeforces account?',
      'answer': 'Go to your Profile and click on "Edit Profile" or tap on the respective rows in your Academic Details section to link your accounts.'
    },
    {
      'question': 'Where can I find my Previous Year Questions (PYQs)?',
      'answer': 'Navigate to the "Study" tab on the bottom navigation bar, and select "PYQs". You can browse subjects and download past papers.'
    },
    {
      'question': 'How is SGPA calculated?',
      'answer': 'Your SGPA is calculated based on the credits and grades achieved in your current semester courses. You can use the SGPA Calculator in the Home tab for quick estimations.'
    },
    {
      'question': 'Can I contribute my handwritten notes?',
      'answer': 'Yes! If you wish to contribute, you can reach out via the contact email below or use the upcoming contribution portal in the app.'
    },
  ];

  bool _isLoadingTickets = true;
  List<Map<String, dynamic>> _tickets = [];

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    final userEmail = Supabase.instance.client.auth.currentUser?.email;
    if (userEmail == null) {
      if (mounted) setState(() => _isLoadingTickets = false);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('support_tickets')
          .select()
          .eq('user_email', userEmail)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _tickets = List<Map<String, dynamic>>.from(data);
          _isLoadingTickets = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTickets = false;
        });
      }
    }
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
          'Help Center',
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Contact Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: nirmaNavy,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: nirmaNavy.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.support_agent_rounded,
                        color: Theme.of(context).colorScheme.surface,
                        size: 32,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'How can we help you?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'It looks like you are experiencing problems with our app. We are here to help so please get in touch with us',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontFamily: 'Manrope',
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: nirmaNavy,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(Icons.edit_document, size: 18),
                      label: Text(
                        'Submit a Ticket',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      onPressed: () => _showSupportForm(context),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Your Tickets Section
              if (!_isLoadingTickets && _tickets.isNotEmpty) ...[
                Text(
                  'Your Tickets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    fontFamily: 'Manrope',
                  ),
                ),
                SizedBox(height: 16),
                ..._tickets.map((ticket) => _buildTicketCard(ticket)).toList(),
                SizedBox(height: 32),
              ] else if (_isLoadingTickets) ...[
                Center(
                  child: CircularProgressIndicator(),
                ),
                SizedBox(height: 32),
              ],

              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  fontFamily: 'Manrope',
                ),
              ),
              SizedBox(height: 16),

              // FAQs
              ...faqs.map((faq) => _buildFaqItem(faq['question']!, faq['answer']!)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final status = (ticket['status'] as String?)?.toLowerCase() ?? 'open';
    final isAdminReplied = ticket['admin_reply'] != null && ticket['admin_reply'].toString().trim().isNotEmpty;
    
    final isResolved = status == 'resolved';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    ticket['subject'] ?? 'No Subject',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isResolved ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isResolved ? Colors.green.withValues(alpha: 0.5) : Colors.orange.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    isResolved ? 'Resolved' : 'Open',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isResolved ? Colors.green[700] : Colors.orange[800],
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              ticket['message'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: textGray,
                fontFamily: 'Manrope',
                height: 1.5,
              ),
            ),
            if (isAdminReplied) ...[
              SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scaffoldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderGray.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.admin_panel_settings, color: nirmaNavy, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Reply',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: nirmaNavy,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            ticket['admin_reply'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: textDark,
                              fontFamily: 'Manrope',
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: nirmaRed,
          collapsedIconColor: textGray,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          title: Text(
            question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textDark,
              fontFamily: 'Manrope',
            ),
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: textGray,
                fontFamily: 'Manrope',
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportForm(BuildContext context) {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Contact Support',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nirmaRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final subject = subjectController.text.trim();
                              final message = messageController.text.trim();

                              if (subject.isEmpty || message.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.surface),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Please fill all fields',
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

                              setModalState(() => isSubmitting = true);

                              try {
                                final userProfile = ref.read(authNotifierProvider).value;
                                final userName = userProfile?.fullName ?? 'Anonymous';
                                final userEmail = Supabase.instance.client.auth.currentUser?.email;

                                await Supabase.instance.client.from('support_tickets').insert({
                                  'subject': subject,
                                  'message': message,
                                  'user_email': userEmail,
                                  'user_name': userName,
                                });

                                if (context.mounted) {
                                  _fetchTickets(); // Refresh tickets list
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.surface),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Ticket submitted successfully! We will get back to you soon.',
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
                                              'Failed to submit ticket. Please try again.',
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
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      child: isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.surface, strokeWidth: 2),
                            )
                          : Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Manrope',
                              ),
                            ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
