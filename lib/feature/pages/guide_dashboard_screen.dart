import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:checking_travel_app/feature/pages/chat_detail.dart';

class GuideDashboardScreen extends StatefulWidget {
  const GuideDashboardScreen({super.key});

  @override
  State<GuideDashboardScreen> createState() => _GuideDashboardScreenState();
}

class _GuideDashboardScreenState extends State<GuideDashboardScreen> {
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _updateRequestStatus(String requestId, String newStatus, String touristId) async {
    try {
      await FirebaseFirestore.instance.collection('tour_requests').doc(requestId).update({
        'status': newStatus,
      });

      String message = newStatus == 'Accepted'
          ? 'Hướng dẫn viên đã chấp nhận yêu cầu của bạn!'
          : 'Rất tiếc, Hướng dẫn viên đã từ chối yêu cầu thuê.';

      await FirebaseFirestore.instance.collection('users').doc(touristId).collection('notifications').add({
        'type': 'tour_response',
        'title': 'Phản hồi từ HDV',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(newStatus == 'Accepted' ? 'Đã chấp nhận tour!' : 'Đã từ chối tour.')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // --- ĐÃ SỬA LẠI LOGIC NÚT HỦY ĐĂNG KÝ CỰC CHUẨN ---
  void _handleUnregisterGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Hủy đăng ký HDV?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn sẽ không còn xuất hiện trong danh sách tìm kiếm. Bạn có chắc chắn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Quay lại', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // 1. Đóng Dialog xác nhận

              // 2. Bật màn hình Loading xoay xoay
              showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

              try {
                // 3. Xóa dữ liệu
                await FirebaseFirestore.instance.collection('users').doc(_currentUserId).update({'isGuide': false});
                await FirebaseFirestore.instance.collection('guides').doc(_currentUserId).delete();

                if (mounted) {
                  Navigator.pop(context); // 4. Tắt vòng xoay Loading
                  Navigator.pop(context); // 5. Thoát khỏi màn Dashboard về trang Cài đặt (Settings)
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gỡ hồ sơ Hướng dẫn viên thành công!'), backgroundColor: Colors.orange));
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Tắt vòng xoay nếu lỗi
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            },
            child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Kênh Hướng dẫn viên', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 1, iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('guides').doc(_currentUserId).snapshots(),
        builder: (context, snapshot) {
          // --- ĐÃ SỬA LẠI LOGIC XỬ LÝ LỖI Ở ĐÂY ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Nếu đã hủy đăng ký (xóa doc) thì báo dòng chữ này chứ không xoay nữa
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text('Bạn đã gỡ hồ sơ Hướng dẫn viên.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 35, backgroundColor: Colors.blue[100],
                      // Nếu có ảnh từ DB thì load ảnh, không thì lấy chữ cái đầu
                      backgroundImage: (data['avatarUrl'] != null && data['avatarUrl'].toString().isNotEmpty)
                          ? NetworkImage(data['avatarUrl'])
                          : null,
                      child: (data['avatarUrl'] == null || data['avatarUrl'].toString().isEmpty)
                          ? Text(data['fullName'][0].toUpperCase(), style: const TextStyle(fontSize: 30, color: Colors.blue, fontWeight: FontWeight.bold))
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(data['fullName'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text(data['province'], style: const TextStyle(color: Colors.grey, fontSize: 16)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatCard('Đánh giá', '${data['rating'] ?? 5.0}', Icons.star, Colors.amber),
                    const SizedBox(width: 15),
                    _buildStatCard('Lượt đặt', '${data['bookings'] ?? 0}', Icons.calendar_today, Colors.blue),
                  ],
                ),
                const SizedBox(height: 30),

                // --- DANH SÁCH YÊU CẦU DẪN TOUR ---
                const Text('Quản lý yêu cầu dẫn tour', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('tour_requests')
                      .where('guideId', isEqualTo: _currentUserId)
                      .where('status', whereIn: ['Pending', 'Accepted'])
                      .snapshots(),
                  builder: (context, tourSnapshot) {
                    if (!tourSnapshot.hasData) return const SizedBox();
                    final requests = tourSnapshot.data!.docs;

                    if (requests.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                        child: const Text('Hiện chưa có yêu cầu nào.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      );
                    }

                    return Column(
                      children: requests.map((doc) {
                        final tourData = doc.data() as Map<String, dynamic>;
                        final String status = tourData['status'] ?? 'Pending';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            title: Text(tourData['touristName'] ?? 'Khách du lịch', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Giá: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(tourData['price'])}'),
                            trailing: status == 'Pending'
                                ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => _updateRequestStatus(doc.id, 'Rejected', tourData['touristId']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => _updateRequestStatus(doc.id, 'Accepted', tourData['touristId']),
                                ),
                              ],
                            )
                                : ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatDetailScreen(
                                      receiverId: tourData['touristId'],
                                      receiverName: tourData['touristName'],
                                      receiverAvatar: tourData['touristAvatar'] ?? '',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.message, size: 18, color: Colors.white),
                              label: const Text('Nhắn tin', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 30),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_off_outlined, color: Colors.red),
                  title: const Text('Hủy đăng ký Hướng dẫn viên', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: _handleUnregisterGuide,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}