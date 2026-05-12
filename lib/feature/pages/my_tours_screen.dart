import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyToursScreen extends StatefulWidget {
  const MyToursScreen({super.key});

  @override
  State<MyToursScreen> createState() => _MyToursScreenState();
}

class _MyToursScreenState extends State<MyToursScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // --- HÀM XỬ LÝ KHI KHÁCH HÀNG BẤM ĐÁNH GIÁ ---
  void _showReviewDialog(BuildContext context, String requestId, String guideId, String guideName) {
    int _rating = 5;
    final TextEditingController _reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                title: Text('Đánh giá $guideName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Bạn cảm thấy chuyến đi thế nào?', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: Colors.amber, size: 35,
                          ),
                          onPressed: () {
                            setState(() { _rating = index + 1; });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _reviewController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Chia sẻ trải nghiệm của bạn...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true, fillColor: Colors.grey[100],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => _submitReview(context, requestId, guideId, _rating, _reviewController.text),
                    child: const Text('Gửi đánh giá', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  // --- HÀM TÍNH TOÁN LẠI SỐ SAO VÀ ĐẨY LÊN FIREBASE ---
  Future<void> _submitReview(BuildContext context, String requestId, String guideId, int userRating, String reviewText) async {
    Navigator.pop(context); // Đóng Dialog chọn sao

    // Bật Dialog Loading xoay xoay
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final guideRef = FirebaseFirestore.instance.collection('guides').doc(guideId);
      final requestRef = FirebaseFirestore.instance.collection('tour_requests').doc(requestId);

      // Kéo dữ liệu hiện tại của HDV về để tính toán
      final guideDoc = await guideRef.get();

      if (guideDoc.exists) {
        final data = guideDoc.data()!;
        double currentRating = (data['rating'] ?? 5.0).toDouble();
        int currentBookings = data['bookings'] ?? 0;

        // THUẬT TOÁN TÍNH TRUNG BÌNH CỘNG SỐ SAO
        int newBookings = currentBookings + 1;
        double newRating = ((currentRating * currentBookings) + userRating) / newBookings;

        // Cập nhật lại sao và lượt đặt cho HDV
        await guideRef.update({
          'rating': double.parse(newRating.toStringAsFixed(1)),
          'bookings': newBookings,
        });
      }

      // LUÔN LUÔN Cập nhật trạng thái chuyến đi thành 'Completed' (Kể cả khi không tìm thấy HDV)
      await requestRef.update({
        'status': 'Completed',
        'rating': userRating,
        'review': reviewText,
      });

      // Tắt Loading và hiện thông báo thành công
      if (context.mounted) {
        Navigator.pop(context); // Đóng Loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!'), backgroundColor: Colors.green));
      }

    } catch (e) {
      // NẾU CÓ LỖI: Tắt Loading và báo lỗi
      if (context.mounted) {
        Navigator.pop(context); // Đóng Loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Lịch sử Thuê HDV', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 1, iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: currentUserId == null
          ? const Center(child: Text('Vui lòng đăng nhập!'))
          : StreamBuilder<QuerySnapshot>(
        // ĐÃ SỬA: Xóa .orderBy() để tránh lỗi Index của Firebase
        stream: FirebaseFirestore.instance.collection('tour_requests').where('touristId', isEqualTo: currentUserId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Bạn chưa có chuyến đi nào.', style: TextStyle(color: Colors.grey, fontSize: 16)));
          }

          // Lấy danh sách tài liệu
          final requests = snapshot.data!.docs;

          // THUẬT TOÁN SẮP XẾP BẰNG DART (Mới nhất lên đầu)
          requests.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            Timestamp? timeA = dataA['createdAt'] as Timestamp?;
            Timestamp? timeB = dataB['createdAt'] as Timestamp?;
            if (timeA == null || timeB == null) return 0;
            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;

              final String guideName = data['guideName'] ?? 'Hướng dẫn viên';
              final int price = data['price'] ?? 0;
              final String status = data['status'] ?? 'Pending';
              final Timestamp? time = data['createdAt'];

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('HDV: $guideName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          _buildStatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Ngày đặt: ${time != null ? DateFormat('dd/MM/yyyy HH:mm').format(time.toDate()) : 'Đang cập nhật'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),

                      if (status != 'Completed' && status != 'Rejected') ...[
                        const Divider(height: 25),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            onPressed: () => _showReviewDialog(context, doc.id, data['guideId'], guideName),
                            child: const Text('Hoàn thành chuyến đi & Đánh giá', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],

                      if (status == 'Completed') ...[
                        const Divider(height: 25),
                        Row(
                          children: [
                            const Text('Đánh giá của bạn: ', style: TextStyle(color: Colors.grey)),
                            ...List.generate(5, (i) => Icon(i < (data['rating'] ?? 5) ? Icons.star : Icons.star_border, color: Colors.amber, size: 18)),
                          ],
                        ),
                        if (data['review'] != null && data['review'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text('"${data['review']}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                          )
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color; String text;
    switch (status) {
      case 'Accepted': color = Colors.blue; text = 'Đã chấp nhận'; break;
      case 'Rejected': color = Colors.red; text = 'Đã từ chối'; break;
      case 'Completed': color = Colors.green; text = 'Đã hoàn thành'; break;
      default: color = Colors.orange; text = 'Đang chờ';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}