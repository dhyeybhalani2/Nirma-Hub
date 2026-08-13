class UserProfile {
  final String id;
  final String fullName;
  final String rollNo;
  final String academicYear;
  final String graduationYear;
  final String division;
  final String batch;
  final String branch;
  final String? profileImageUrl;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.rollNo,
    required this.academicYear,
    required this.graduationYear,
    required this.division,
    required this.batch,
    required this.branch,
    this.profileImageUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      rollNo: json['roll_no'] ?? '',
      academicYear: json['academic_year'] ?? '',
      graduationYear: json['graduation_year'] ?? '',
      division: json['division'] ?? '',
      batch: json['batch'] ?? '',
      branch: json['branch'] ?? '',
      profileImageUrl: json['profile_image_url'],
    );
  }
}