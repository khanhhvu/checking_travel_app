import 'dart:convert';
import 'dart:math';
import 'package:checking_travel_app/data/models/hotel_model.dart';
import 'package:http/http.dart' as http;


class HotelApiService {
  // Key Rapid API thật của bạn
  static const String _pricingApiKey = 'cfc0106551msh21b81a2d9eb7b34p154e1djsn3452c9b660c8';
  static const String _rapidApiHost = 'booking-com.p.rapidapi.com';

  // --- Tọa độ giả lập của người dùng (VD: Đang ở trung tâm Hà Nội) ---
  final double userLat = 21.0285;
  final double userLng = 105.8542;

  // =================================================================
  // HÀM CHÍNH: TỔNG HỢP, LỌC VÀ SẮP XẾP DỮ LIỆU
  // =================================================================
  Future<List<HotelModel>> fetchCompleteHotels(String cityName) async {
    try {
      // 1. Kéo dữ liệu khách sạn (Đã lọc theo thành phố)
      List<HotelModel> hotels = await _getHotelsFromGoogle(cityName);

      if (hotels.isEmpty) return [];

      // 2. Sắp xếp khách sạn theo khoảng cách (Gần nhất lên đầu)
      hotels.sort((a, b) {
        double distA = _calculateDistance(userLat, userLng, a.lat, a.lng);
        double distB = _calculateDistance(userLat, userLng, b.lat, b.lng);
        return distA.compareTo(distB);
      });

      // 3. Gọi API lấy giá thật cho các khách sạn
      await Future.wait(hotels.map((hotel) async {
        String price = await _getPriceFromThirdParty(hotel.name, hotel.lat, hotel.lng);
        hotel.price = price;
      }));

      return hotels;
    } catch (e) {
      throw Exception('Lỗi tổng hợp dữ liệu: $e');
    }
  }

  // =================================================================
  // HÀM PHỤ 1: TRẢ VỀ MOCK DATA (CÓ LỌC THEO TỪ KHÓA)
  // =================================================================
  Future<List<HotelModel>> _getHotelsFromGoogle(String city) async {
    await Future.delayed(const Duration(seconds: 1));

    // Kho dữ liệu tổng (Bạn có thể thêm nhiều hơn)
    List<HotelModel> allHotels = [
      HotelModel(id: 'g1', name: 'Meliá Hanoi', address: '44B Lý Thường Kiệt, Hoàn Kiếm, Hà Nội', imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800', rating: 4.6, lat: 21.0238, lng: 105.8488),
      HotelModel(id: 'g2', name: 'Hilton Da Nang', address: '50 Bạch Đằng, Hải Châu, Đà Nẵng', imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c0d51928?w=800', rating: 4.5, lat: 16.0717, lng: 108.2241),
      HotelModel(id: 'g3', name: 'Vinpearl Landmark 81', address: '720A Điện Biên Phủ, TP. Hồ Chí Minh', imageUrl: 'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800', rating: 4.8, lat: 10.7956, lng: 106.7218),
      HotelModel(id: 'g4', name: 'Hotel de la Coupole', address: '1 Hoàng Liên, Sapa, Lào Cai', imageUrl: 'https://images.unsplash.com/photo-1542314831-c6a420325142?w=800', rating: 4.9, lat: 22.3352, lng: 103.8436),
      HotelModel(id: 'g5', name: 'InterContinental Nha Trang', address: '32-34 Trần Phú, Nha Trang, Khánh Hòa', imageUrl: 'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800', rating: 4.7, lat: 12.2435, lng: 109.1963),
      HotelModel(id: 'g6', name: 'JW Marriott Hotel Hanoi', address: '8 Đỗ Đức Dục, Nam Từ Liêm, Hà Nội', imageUrl: 'https://images.unsplash.com/photo-1618773928120-16a4d08cb0e4?w=800', rating: 4.8, lat: 21.0084, lng: 105.7876),
      HotelModel(id: 'g7', name: 'Somerset Grand Hanoi', address: '49 Hai Bà Trưng, Hoàn Kiếm, Hà Nội', imageUrl: 'https://images.unsplash.com/photo-1596436889106-be35e843f974?w=800', rating: 4.4, lat: 21.0255, lng: 105.8471),
    ];

    // Lọc: Nếu từ khóa xuất hiện trong tên hoặc địa chỉ (không phân biệt hoa thường)
    String query = city.toLowerCase();
    return allHotels.where((hotel) {
      return hotel.address.toLowerCase().contains(query) || hotel.name.toLowerCase().contains(query);
    }).toList();
  }

  // =================================================================
  // HÀM PHỤ 2: GỌI RAPIDAPI LẤY GIÁ PHÒNG (DÙNG MOCK NẾU API THẬT PHỨC TẠP)
  // =================================================================
  Future<String> _getPriceFromThirdParty(String hotelName, double lat, double lng) async {
    // --- GIẢI THÍCH VỀ API GIÁ THẬT ---
    // Để lấy giá thật từ Booking API, bạn cần truyền RẤT NHIỀU thông số (ngày check-in, check-out, số người, dest_id...).
    // Ví dụ một endpoint tìm giá thực tế sẽ trông như thế này:
    // final url = Uri.parse('https://$_rapidApiHost/v1/hotels/search?dest_id=-3714993&search_type=city&arrival_date=2024-05-10&departure_date=2024-05-12&adults=2&room_qty=1');
    //
    // Tuy nhiên, việc lấy được 'dest_id' (ID của thành phố/khách sạn trên Booking) đòi hỏi phải gọi thêm 1 API nữa.
    // Vì vậy, để UI hoàn thiện nhanh, mình sẽ viết một hàm mô phỏng việc gọi API lấy giá.
    // Khi bạn sẵn sàng tích hợp logic chọn ngày tháng (Date Picker), chúng ta sẽ ráp API thật vào đoạn này.

    await Future.delayed(const Duration(milliseconds: 500)); // Giả lập chờ API

    // Thuật toán tạo giá ngẫu nhiên nhưng cố định cho mỗi khách sạn (dựa vào độ dài tên)
    int basePrice = 800000;
    int randomMultiplier = (hotelName.length * 12345) % 15;
    int finalPrice = basePrice + (randomMultiplier * 150000);

    // Format thành dạng tiền tệ: 1.500.000đ
    String formattedPrice = "${(finalPrice / 1000).toStringAsFixed(0)}.000đ";
    return formattedPrice;
  }

  // =================================================================
  // HÀM PHỤ 3: TOÁN HỌC - TÍNH KHOẢNG CÁCH GIỮA 2 TỌA ĐỘ (HAVERSINE FORMULA)
  // =================================================================
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}