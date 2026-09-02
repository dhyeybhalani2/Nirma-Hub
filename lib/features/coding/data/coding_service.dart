import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/coding_profile_model.dart';
import '../../auth/domain/user_profile.dart';

class CodingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Verify and fetch LeetCode stats using official GraphQL
  Future<Map<String, dynamic>?> fetchLeetCodeStats(String username) async {
    try {
      final response = await http.post(
        Uri.parse('https://leetcode.com/graphql'),
        headers: {
          'Content-Type': 'application/json',
          // A User-Agent is required for LeetCode's public GraphQL
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36'
        },
        body: jsonEncode({
          'query': '''
            query getUserProfile(\$username: String!) {
              matchedUser(username: \$username) {
                profile {
                  ranking
                }
                submitStats {
                  acSubmissionNum {
                    difficulty
                    count
                  }
                }
              }
              userContestRanking(username: \$username) {
                rating
              }
            }
          ''',
          'variables': {'username': username}
        }),
      );

      if (response.statusCode != 200) return null;
      
      final data = jsonDecode(response.body);
      
      // If user doesn't exist, matchedUser is null
      if (data['data'] == null || data['data']['matchedUser'] == null) {
        return null;
      }
      
      final matchedUser = data['data']['matchedUser'];
      final contestData = data['data']['userContestRanking'];
      
      final ranking = matchedUser['profile']?['ranking'] ?? 0;
      
      // Find the 'All' difficulty count for total solved
      int solved = 0;
      final submissions = matchedUser['submitStats']?['acSubmissionNum'] as List<dynamic>? ?? [];
      for (var sub in submissions) {
        if (sub['difficulty'] == 'All') {
          solved = sub['count'] ?? 0;
          break;
        }
      }
      
      double rating = 0;
      if (contestData != null && contestData['rating'] != null) {
        rating = (contestData['rating'] as num).toDouble();
      }

      return {
        'ranking': ranking,
        'solved': solved,
        'rating': rating.round(),
      };
    } catch (e) {
      print('Error fetching LeetCode stats: \$e');
      return null;
    }
  }

  // Verify and fetch Codeforces stats
  Future<Map<String, dynamic>?> fetchCodeforcesStats(String username) async {
    try {
      final res = await http.get(Uri.parse('https://codeforces.com/api/user.info?handles=$username'));
      if (res.statusCode != 200) return null;
      
      final data = jsonDecode(res.body);
      if (data['status'] != 'OK') return null;

      final result = data['result'][0];
      return {
        'rating': result['rating'] ?? 0,
        'maxRating': result['maxRating'] ?? 0,
      };
    } catch (e) {
      print('Error fetching Codeforces stats: $e');
      return null;
    }
  }

  // Get current user's coding profile from Supabase
  Future<CodingProfile?> getCurrentCodingProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _supabase
          .from('coding_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      if (data != null) {
        return CodingProfile.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching coding profile: $e');
      return null;
    }
  }

  // Update LeetCode profile
  Future<bool> linkLeetCode(String username, UserProfile userProfile) async {
    final stats = await fetchLeetCodeStats(username);
    if (stats == null) return false;

    return await _upsertProfile(
      userProfile,
      leetcodeUsername: username,
      leetcodeRanking: stats['ranking'],
      leetcodeSolved: stats['solved'],
      leetcodeRating: stats['rating'],
    );
  }

  // Update Codeforces profile
  Future<bool> linkCodeforces(String username, UserProfile userProfile) async {
    final stats = await fetchCodeforcesStats(username);
    if (stats == null) return false;

    return await _upsertProfile(
      userProfile,
      codeforcesUsername: username,
      codeforcesRating: stats['rating'],
      codeforcesMaxRating: stats['maxRating'],
    );
  }

  // Unlink LeetCode profile
  Future<bool> unlinkLeetCode(UserProfile userProfile) async {
    try {
      final currentProfile = await getCurrentCodingProfile();
      if (currentProfile == null) return false;

      final Map<String, dynamic> data = {
        'id': userProfile.id,
        'full_name': userProfile.fullName,
        'roll_no': userProfile.rollNo,
        'branch': userProfile.branch,
        'academic_year': userProfile.academicYear,
        'division': userProfile.division,
        'updated_at': DateTime.now().toIso8601String(),
        'leetcode_username': null,
        'leetcode_ranking': null,
        'leetcode_solved': null,
        'leetcode_rating': null,
        'codeforces_username': currentProfile.codeforcesUsername,
        'codeforces_rating': currentProfile.codeforcesRating,
        'codeforces_max_rating': currentProfile.codeforcesMaxRating,
      };

      await _supabase.from('coding_profiles').upsert(data);
      return true;
    } catch (e) {
      print('Error unlinking LeetCode: $e');
      return false;
    }
  }

  // Unlink Codeforces profile
  Future<bool> unlinkCodeforces(UserProfile userProfile) async {
    try {
      final currentProfile = await getCurrentCodingProfile();
      if (currentProfile == null) return false;

      final Map<String, dynamic> data = {
        'id': userProfile.id,
        'full_name': userProfile.fullName,
        'roll_no': userProfile.rollNo,
        'branch': userProfile.branch,
        'academic_year': userProfile.academicYear,
        'division': userProfile.division,
        'updated_at': DateTime.now().toIso8601String(),
        'leetcode_username': currentProfile.leetcodeUsername,
        'leetcode_ranking': currentProfile.leetcodeRanking,
        'leetcode_solved': currentProfile.leetcodeSolved,
        'leetcode_rating': currentProfile.leetcodeRating,
        'codeforces_username': null,
        'codeforces_rating': null,
        'codeforces_max_rating': null,
      };

      await _supabase.from('coding_profiles').upsert(data);
      return true;
    } catch (e) {
      print('Error unlinking Codeforces: $e');
      return false;
    }
  }

  Future<bool> _upsertProfile(
    UserProfile userProfile, {
    String? leetcodeUsername,
    int? leetcodeRanking,
    int? leetcodeSolved,
    int? leetcodeRating,
    String? codeforcesUsername,
    int? codeforcesRating,
    int? codeforcesMaxRating,
  }) async {
    try {
      final currentProfile = await getCurrentCodingProfile();

      final Map<String, dynamic> data = {
        'id': userProfile.id,
        'full_name': userProfile.fullName,
        'roll_no': userProfile.rollNo,
        'branch': userProfile.branch,
        'academic_year': userProfile.academicYear,
        'division': userProfile.division,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Keep existing data if not provided
      if (leetcodeUsername != null) {
        data['leetcode_username'] = leetcodeUsername;
        data['leetcode_ranking'] = leetcodeRanking;
        data['leetcode_solved'] = leetcodeSolved;
        data['leetcode_rating'] = leetcodeRating;
      } else if (currentProfile != null) {
        data['leetcode_username'] = currentProfile.leetcodeUsername;
        data['leetcode_ranking'] = currentProfile.leetcodeRanking;
        data['leetcode_solved'] = currentProfile.leetcodeSolved;
        data['leetcode_rating'] = currentProfile.leetcodeRating;
      }

      if (codeforcesUsername != null) {
        data['codeforces_username'] = codeforcesUsername;
        data['codeforces_rating'] = codeforcesRating;
        data['codeforces_max_rating'] = codeforcesMaxRating;
      } else if (currentProfile != null) {
        data['codeforces_username'] = currentProfile.codeforcesUsername;
        data['codeforces_rating'] = currentProfile.codeforcesRating;
        data['codeforces_max_rating'] = currentProfile.codeforcesMaxRating;
      }

      await _supabase.from('coding_profiles').upsert(data);
      return true;
    } catch (e) {
      print('Error upserting coding profile: $e');
      return false;
    }
  }

  // Get Leaderboards
  Future<List<CodingProfile>> getLeetCodeLeaderboard() async {
    try {
      final data = await _supabase
          .from('coding_profiles')
          .select()
          .not('leetcode_username', 'is', null)
          .order('leetcode_rating', ascending: false);
          
      final list = data.map((json) => CodingProfile.fromJson(json)).toList();
      

      list.sort((a, b) => b.leetcodeRating.compareTo(a.leetcodeRating));
      
      return list;
    } catch (e) {
      print('Error getting LeetCode leaderboard: $e');
      return [];
    }
  }

  Future<List<CodingProfile>> getCodeforcesLeaderboard() async {
    try {
      final data = await _supabase
          .from('coding_profiles')
          .select()
          .not('codeforces_username', 'is', null)
          .order('codeforces_rating', ascending: false);
          
      final list = data.map((json) => CodingProfile.fromJson(json)).toList();
      

      list.sort((a, b) => b.codeforcesRating.compareTo(a.codeforcesRating));
      
      return list;
    } catch (e) {
      print('Error getting Codeforces leaderboard: $e');
      return [];
    }
  }
}
