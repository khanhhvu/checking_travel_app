import 'package:checking_travel_app/data/models/hotel_model.dart';
import 'package:checking_travel_app/feature/pages/booking_screen.dart';
import 'package:flutter/material.dart';


class HotelDetailScreen extends StatelessWidget {
  final HotelModel hotel;

  const HotelDetailScreen({super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // --- ẢNH BÌA CO GIÃN (SLIVER APP BAR) ---
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    hotel.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 50, color: Colors.grey)),
                  ),
                  // Phủ một lớp đen mờ mờ để làm nổi bật nút Back
                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.center, colors: [Colors.black.withOpacity(0.6), Colors.transparent]))),
                ],
              ),
            ),
          ),

          // --- NỘI DUNG CHI TIẾT ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên và Đánh giá
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(hotel.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(hotel.rating.toString(), style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Địa chỉ
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(hotel.address, style: TextStyle(color: Colors.grey[600], fontSize: 15))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Giới thiệu giả lập
                  const Text('Giới thiệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Trải nghiệm kỳ nghỉ tuyệt vời tại ${hotel.name} với các tiện ích đẳng cấp. Nằm ngay vị trí đắc địa, khách sạn cung cấp các phòng nghỉ sang trọng, hồ bơi ngoài trời và nhà hàng phục vụ ẩm thực địa phương cũng như quốc tế.',
                    style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 15),
                  ),
                  const SizedBox(height: 100), // Khoảng trống để không bị nút Đặt phòng che mất chữ
                ],
              ),
            ),
          ),
        ],
      ),

      // --- NÚT ĐẶT PHÒNG Ở DƯỚI CÙNG ---
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Giá mỗi đêm từ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(hotel.price, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(hotel: hotel), // Truyền thông tin KS sang
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Đặt phòng', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}