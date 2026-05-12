import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class GuideDetailScreen extends StatelessWidget {
  final Map<String, dynamic> guideData;
  final String guideId;

  const GuideDetailScreen({super.key, required this.guideData, required this.guideId});

  @override
  Widget build(BuildContext context) {
    final fullName = guideData['fullName'] ?? 'Chưa rõ tên';
    final province = guideData['province'] ?? 'Chưa rõ khu vực';
    final bio = guideData['bio'] ?? 'Chưa có thông tin giới thiệu.';
    final int price = guideData['pricePerDay'] ?? 500000;
    final double rating = (guideData['rating'] ?? 5.0).toDouble();
    final int bookings = guideData['bookings'] ?? 0;
    final avatarUrl = guideData['avatarUrl'] ?? '';

    List<dynamic> skills = guideData['skills'] ?? [];
    if (skills.isEmpty) {
      int len = fullName.length;
      skills = (len % 3 == 0) ? ['Food tour', 'Chụp ảnh'] : (len % 3 == 1) ? ['Lịch sử', 'Ngoại ngữ'] : ['Phượt xe máy'];
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Hồ sơ Hướng dẫn viên', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 1, iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. THÔNG TIN CƠ BẢN ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.blue[100],
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty ? Text(fullName[0].toUpperCase(), style: const TextStyle(fontSize: 40, color: Colors.blue, fontWeight: FontWeight.bold)) : null,
                  ),
                  const SizedBox(height: 15),
                  Text(fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(province, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- 2. CHỈ SỐ THỐNG KÊ ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(Icons.star, Colors.amber, rating.toStringAsFixed(1), 'Đánh giá'),
                      _buildStatColumn(Icons.work, Colors.blue, '$bookings', 'Tour đã dẫn'),
                      _buildStatColumn(Icons.monetization_on, Colors.green, '${(price / 1000).round()}k', 'Giá/Ngày'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // --- 3. GIỚI THIỆU & KỸ NĂNG ---
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Giới thiệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(bio, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
                  const SizedBox(height: 20),
                  const Text('Kỹ năng chuyên môn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: skills.map((skill) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                      child: Text(skill.toString(), style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // --- 4. FEEDBACK (ĐÁNH GIÁ TỪ KHÁCH HÀNG CŨ) ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Đánh giá từ khách hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  // StreamBuilder lấy dữ liệu Feedback
                  StreamBuilder<QuerySnapshot>(
                    // Lấy tất cả tour của HDV này (lọc bằng code Dart để tránh lỗi Index Firebase)
                    stream: FirebaseFirestore.instance.collection('tour_requests').where('guideId', isEqualTo: guideId).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('Chưa có đánh giá nào.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))));
                      }

                      // Lọc ra những tour đã hoàn thành (Completed) VÀ có viết review
                      final reviews = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['status'] == 'Completed' && data['review'] != null && data['review'].toString().trim().isNotEmpty;
                      }).toList();

                      // Sắp xếp bài đánh giá mới nhất lên đầu
                      reviews.sort((a, b) {
                        Timestamp? timeA = (a.data() as Map<String, dynamic>)['createdAt'];
                        Timestamp? timeB = (b.data() as Map<String, dynamic>)['createdAt'];
                        if (timeA == null || timeB == null) return 0;
                        return timeB.compareTo(timeA);
                      });

                      if (reviews.isEmpty) {
                        return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('Chưa có đánh giá nào.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))));
                      }

                      // Vẽ danh sách Feedback
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final reviewData = reviews[index].data() as Map<String, dynamic>;
                          final reviewerName = reviewData['touristName'] ?? 'Khách ẩn danh';
                          final int userRating = reviewData['rating'] ?? 5;
                          final String reviewText = reviewData['review'] ?? '';
                          final Timestamp? time = reviewData['createdAt'];

                          // Lấy chữ cái đầu làm Avatar giả
                          String initial = reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : 'U';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey[200]!)
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Avatar khách hàng
                                    CircleAvatar(
                                      radius: 20, backgroundColor: Colors.grey[300],
                                      child: Text(initial, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Tên khách hàng
                                          Text(reviewerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          const SizedBox(height: 4),
                                          // Hiển thị số sao vàng
                                          Row(children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < userRating ? Colors.amber : Colors.grey[300]))),
                                        ],
                                      ),
                                    ),
                                    // Ngày đánh giá
                                    Text(time != null ? DateFormat('dd/MM/yyyy').format(time.toDate()) : '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Nội dung Feedback
                                Text('"$reviewText"', style: const TextStyle(fontSize: 14, color: Colors.black87, fontStyle: FontStyle.italic, height: 1.4)),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      // --- NÚT THUÊ DƯỚI CÙNG MÀN HÌNH ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))]),
        child: ElevatedButton(
          onPressed: () async {
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            if (currentUserId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để thuê HDV!')));
              return;
            }
            if (currentUserId == guideId) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn không thể tự thuê chính mình!')));
              return;
            }

            showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
            try {
              await FirebaseFirestore.instance.collection('tour_requests').add({
                'guideId': guideId,
                'guideName': fullName,
                'touristId': currentUserId,
                'touristName': FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.email ?? 'Khách hàng',
                'touristAvatar': FirebaseAuth.instance.currentUser?.photoURL ?? '',
                'price': price,
                'status': 'Pending',
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context); // Tắt loading
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã gửi yêu cầu thuê $fullName!'), backgroundColor: Colors.green));
                Navigator.pop(context); // Trở về màn hình tìm kiếm
              }
            } catch (e) {
              if (context.mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Gửi yêu cầu thuê', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}