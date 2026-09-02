class LostAndFoundItem {
  final String id;
  final String title;
  final String location;
  final String date;
  final bool isLost;
  final String imagePath;
  final String description;
  final String personName;
  final String contactNumber;
  final String email;
  final bool isSuccessful;
  final String userId;

  LostAndFoundItem({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.isLost,
    required this.imagePath,
    required this.description,
    required this.personName,
    required this.contactNumber,
    required this.email,
    this.isSuccessful = false,
    required this.userId,
  });

  factory LostAndFoundItem.fromJson(Map<String, dynamic> json) {
    return LostAndFoundItem(
      id: json['id'] as String,
      title: json['title'] as String,
      location: json['location'] as String,
      date: json['date_lost_found'] as String,
      isLost: json['is_lost'] as bool,
      imagePath: json['image_url'] as String? ?? 'https://images.unsplash.com/photo-1584972242131-7e8c3b9b4f9f?auto=format&fit=crop&q=80&w=400&h=400',
      description: json['description'] as String,
      personName: json['person_name'] as String,
      contactNumber: json['contact_number'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isSuccessful: json['is_successful'] as bool? ?? false,
      userId: json['user_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'location': location,
      'date_lost_found': date,
      'is_lost': isLost,
      'image_url': imagePath,
      'description': description,
      'person_name': personName,
      'contact_number': contactNumber,
      'email': email,
      'is_successful': isSuccessful,
      'user_id': userId,
    };
  }
}
