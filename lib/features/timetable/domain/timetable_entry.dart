class TimetableEntry {
  final String academicYear;
  final String branch;
  final String division;
  final String? batch;
  final String day;
  final String startTime;
  final String endTime;
  final String subject;
  final String professor;
  final String location;

  TimetableEntry({
    required this.academicYear,
    required this.branch,
    required this.division,
    this.batch,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.professor,
    required this.location,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      academicYear: json['academicYear'] ?? '',
      branch: json['branch'] ?? '',
      division: json['division'] ?? '',
      batch: json['batch'] == 'ALL' ? null : json['batch'],
      day: json['day'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      subject: json['subject'] ?? '',
      professor: json['professor'] ?? '',
      location: json['location'] ?? '',
    );
  }
}