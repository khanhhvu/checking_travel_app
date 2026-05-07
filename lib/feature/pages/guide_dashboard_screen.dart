import 'package:checking_travel_app/feature/pages/chat_detail.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GuideDashboardScreen extends StatelessWidget {
  const GuideDashboardScreen({super.key});

  // Hàm xử lý khi HDV bấm nút Duyệt hoặc Từ chối
  Future<void> _updateRequestStatus(BuildContext context, String docId,
      String newStatus, String touristId, String guideName) async {
    try {
      // Cập nhật trạng thái Tour
      await FirebaseFirestore.instance
          .collection('tour_requests')
          .doc(docId)
          .update({
        'status': newStatus,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(touristId)
          .collection('notifications')
          .add({
        'type': newStatus == 'Accepted' ? 'tour_accepted' : 'tour_declined',
        'senderName': guideName,
        'senderAvatar': '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                newStatus == 'Accepted' ? 'Đã nhận Tour!' : 'Đã từ chối Tour!'),
            backgroundColor:
                newStatus == 'Accepted' ? Colors.green : Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Hướng dẫn viên';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Kênh Hướng dẫn viên',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            tooltip: 'Thoát kênh HDV',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chào mừng,\n$displayName! 👋',
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            const Text('Yêu cầu đặt lịch gần đây',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tour_requests')
                  .where('guideId',
                      isEqualTo: user?.uid) // Chỉ kéo yêu cầu của ông HDV này
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[300]!)),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 15),
                        Text('Chưa có yêu cầu dẫn tour nào.',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  );
                }

                // Chuyển về List và Sắp xếp đơn mới nhất lên đầu
                List<QueryDocumentSnapshot> requests = snapshot.data!.docs;
                requests.sort((a, b) {
                  Timestamp? tA = (a.data() as Map)['createdAt'];
                  Timestamp? tB = (b.data() as Map)['createdAt'];
                  if (tA == null || tB == null) return 0;
                  return tB.compareTo(tA);
                });

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final data = requests[index].data() as Map<String, dynamic>;
                    final docId = requests[index].id;
                    final touristName = data['touristName'] ?? 'Người lạ';
                    final status = data['status'] ?? 'Pending';
                    final price = data['price'] ?? 0;
                    final touristId = data['touristId'] ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                        backgroundColor: Colors.orange[100],
                                        child: const Icon(Icons.person,
                                            color: Colors.orange)),
                                    const SizedBox(width: 10),
                                    Text(touristName,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Text(
                                    NumberFormat.currency(
                                            locale: 'vi_VN', symbol: 'đ')
                                        .format(price),
                                    style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 20),

                            // KIỂM TRA TRẠNG THÁI ĐỂ HIỂN THỊ NÚT
                            if (status == 'Pending')
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _updateRequestStatus(
                                          context,
                                          docId,
                                          'Declined',
                                          data['touristId'],
                                          displayName),
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(
                                              color: Colors.red)),
                                      child: const Text('Từ chối'),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _updateRequestStatus(
                                          context,
                                          docId,
                                          'Accepted',
                                          data['touristId'],
                                          displayName),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                      child: const Text('Chấp nhận',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ],
                              )
                            else if (status == 'Accepted')
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: const Center(
                                          child: Text('Đã nhận Tour',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // NÚT NHẮN TIN VỚI KHÁCH HÀNG
                                  InkWell(
                                    onTap: () {
                                      if (touristId.isEmpty) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ChatDetailScreen(
                                            receiverId: touristId,
                                            receiverName: touristName,
                                            receiverAvatar: '',
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: const Icon(
                                          Icons.chat_bubble_outline,
                                          color: Colors.blue),
                                    ),
                                  )
                                ],
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Center(
                                    child: Text(' Đã từ chối dẫn Tour này',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold))),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
