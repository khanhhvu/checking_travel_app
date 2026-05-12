import 'package:cloud_firestore/cloud_firestore.dart';

class HotelModel {
  final String id;
  final String name;
  final String address;
  final String imageUrl;
  final double rating;
  final double lat;
  final double lng;
  String price;

  HotelModel({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.rating,
    required this.lat,
    required this.lng,
    required this.price,
  });

  // Hàm chuyển đổi dữ liệu từ Firebase sang Model của Flutter
  factory HotelModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // 1. Lấy giá tiền dạng số từ Firebase
    int rawPrice = (data['price'] ?? 0).toInt();

    // 2. Format giá tiền luôn (Ví dụ: 1500000 -> "1.500.000đ")
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String Function(Match) mathFunc = (Match match) => '${match[1]}.';
    String formattedPrice = '${rawPrice.toString().replaceAllMapped(reg, mathFunc)}đ';

    return HotelModel(
      id: doc.id,
      name: data['name'] ?? 'Khách sạn chưa cập nhật tên',
      address: data['address'] ?? 'Chưa cập nhật địa chỉ',
      imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/400x200?text=No+Image',
      rating: (data['rating'] ?? 0.0).toDouble(),
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      price: formattedPrice, // Đưa giá đã format vào
    );
  }
}