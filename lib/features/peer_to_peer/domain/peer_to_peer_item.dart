class PeerToPeerItem {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double price;
  final String condition;
  final String category;
  final String imagePath;
  final String contactNumber;
  final String sellerName;
  final bool isSold;
  final DateTime createdAt;

  PeerToPeerItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.price,
    required this.condition,
    required this.category,
    required this.imagePath,
    required this.contactNumber,
    required this.sellerName,
    required this.isSold,
    required this.createdAt,
  });

  factory PeerToPeerItem.fromJson(Map<String, dynamic> json) {
    return PeerToPeerItem(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      condition: json['condition'],
      category: json['category'],
      imagePath: json['image_path'],
      contactNumber: json['contact_number'],
      sellerName: json['seller_name'],
      isSold: json['is_sold'] ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}
