class CodingProfile {
  final String id;
  final String fullName;
  final String rollNo;
  final String? branch;
  final String? academicYear;
  final String? division;
  final String? leetcodeUsername;
  final int leetcodeSolved;
  final int leetcodeRanking;
  final int leetcodeRating;
  final String? codeforcesUsername;
  final int codeforcesRating;
  final int codeforcesMaxRating;
  final DateTime updatedAt;

  CodingProfile({
    required this.id,
    required this.fullName,
    required this.rollNo,
    this.branch,
    this.academicYear,
    this.division,
    this.leetcodeUsername,
    required this.leetcodeSolved,
    required this.leetcodeRanking,
    required this.leetcodeRating,
    this.codeforcesUsername,
    required this.codeforcesRating,
    required this.codeforcesMaxRating,
    required this.updatedAt,
  });

  factory CodingProfile.fromJson(Map<String, dynamic> json) {
    return CodingProfile(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      rollNo: json['roll_no'] ?? '',
      branch: json['branch'],
      academicYear: json['academic_year'],
      division: json['division'],
      leetcodeUsername: json['leetcode_username'],
      leetcodeSolved: json['leetcode_solved'] ?? 0,
      leetcodeRanking: json['leetcode_ranking'] ?? 0,
      leetcodeRating: json['leetcode_rating'] ?? 0,
      codeforcesUsername: json['codeforces_username'],
      codeforcesRating: json['codeforces_rating'] ?? 0,
      codeforcesMaxRating: json['codeforces_max_rating'] ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'roll_no': rollNo,
      'leetcode_username': leetcodeUsername,
      'leetcode_solved': leetcodeSolved,
      'leetcode_ranking': leetcodeRanking,
      'codeforces_username': codeforcesUsername,
      'codeforces_rating': codeforcesRating,
      'codeforces_max_rating': codeforcesMaxRating,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
