import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:checking_travel_app/data/models/hotel_model.dart';

class HotelApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tọa độ mặc định: Đại học Giao thông Vận tải (UTC) - Cầu Giấy, Hà Nội
  static const double utcLat = 21.0278;
  static const double utcLng = 105.8052;

  // =================================================================
  // HÀM CHÍNH: LẤY DỮ LIỆU TỪ FIREBASE + LỌC + SẮP XẾP THEO UTC
  // =================================================================
  Future<List<HotelModel>> fetchCompleteHotels(String cityName) async {
    try {
      // 1. Kéo toàn bộ danh sách Khách sạn từ Firebase
      QuerySnapshot snapshot = await _firestore.collection('hotels').get();

      if (snapshot.docs.isEmpty) return [];

      // 2. Chuyển đổi dữ liệu và Lọc theo thành phố người dùng tìm kiếm
      String query = cityName.toLowerCase().trim();

      List<HotelModel> hotels = snapshot.docs.map((doc) {
        return HotelModel.fromFirestore(doc);
      }).where((hotel) {
        // Tìm kiếm không phân biệt hoa thường trong Địa chỉ hoặc Tên KS
        return hotel.address.toLowerCase().contains(query) ||
            hotel.name.toLowerCase().contains(query);
      }).toList();

      // 3. Sắp xếp khách sạn theo khoảng cách (Từ trường GTVT đến Khách sạn)
      hotels.sort((a, b) {
        double distA = _calculateDistance(utcLat, utcLng, a.lat, a.lng);
        double distB = _calculateDistance(utcLat, utcLng, b.lat, b.lng);
        return distA.compareTo(distB);
      });

      return hotels;
    } catch (e) {
      throw Exception('Lỗi tải dữ liệu: $e');
    }
  }

  // =================================================================
  // HÀM PHỤ: TÍNH KHOẢNG CÁCH (HAVERSINE FORMULA)
  // =================================================================
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    double a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 12742 = 2 * R (R = 6371 km)
  }
}