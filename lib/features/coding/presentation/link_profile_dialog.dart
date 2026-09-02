import 'package:flutter/material.dart';
import '../data/coding_service.dart';
import '../../auth/domain/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class LinkProfileDialog extends ConsumerStatefulWidget {
  final bool isLeetCode; // true for LeetCode, false for Codeforces

  const LinkProfileDialog({super.key, required this.isLeetCode});

  @override
  ConsumerState<LinkProfileDialog> createState() => _LinkProfileDialogState();
}

class _LinkProfileDialogState extends ConsumerState<LinkProfileDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final CodingService _codingService = CodingService();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _linkProfile() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'Please enter a username');
      return;
    }

    final userProfile = ref.read(authNotifierProvider).value;
    if (userProfile == null) {
      setState(() => _error = 'User not authenticated');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Fetch stats first
    Map<String, dynamic>? stats;
    if (widget.isLeetCode) {
      stats = await _codingService.fetchLeetCodeStats(username);
    } else {
      stats = await _codingService.fetchCodeforcesStats(username);
    }

    if (stats == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Invalid username or failed to fetch stats.';
        });
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    final primaryColor = widget.isLeetCode ? const Color(0xFFC62828) : const Color(0xFF3B82F6);

    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Is this your profile? You can change this later.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 16),
            if (widget.isLeetCode) ...[
              Text('Contest Rating: ${(stats!["rating"] as num) > 0 ? stats!["rating"] : "N/A"}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Global Rank: ${(stats!["ranking"] as num) > 0 ? "#${stats!["ranking"]}" : "N/A"}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Problems Solved: ${stats!["solved"]}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ] else ...[
              Text('Current Rating: ${stats?["rating"] ?? "N/A"}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Max Rating: ${stats?["maxRating"] ?? "N/A"}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
            child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Yes, Link It', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    bool success = false;
    if (widget.isLeetCode) {
      success = await _codingService.linkLeetCode(username, userProfile);
    } else {
      success = await _codingService.linkCodeforces(username, userProfile);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop(true); // Return true on success
      } else {
        setState(() {
          _error = 'Failed to link profile.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = widget.isLeetCode ? 'LeetCode' : 'Codeforces';
    final primaryColor = widget.isLeetCode ? const Color(0xFFC62828) : const Color(0xFF3B82F6);

    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Link $platform', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enter your $platform username to link it to your profile and appear on the leaderboard.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              errorText: _error,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
          child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _linkProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading 
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.surface))
            : Text('Link', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
