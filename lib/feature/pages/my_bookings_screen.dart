import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Lấy ID của người dùng đang đăng nhập
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Khách sạn của tôi',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // 2. Nếu chưa đăng nhập thì báo lỗi
      body: currentUser == null
          ? const Center(
              child: Text('Vui lòng đăng nhập để xem lịch sử!',
                  style: TextStyle(fontSize: 16)))
          : StreamBuilder<QuerySnapshot>(
              // 3. Query Firebase: Lọc collection 'bookings' theo 'userId'
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('userId', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Đã xảy ra lỗi khi tải dữ liệu.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Bạn chưa đặt khách sạn nào.',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                // Lấy danh sách booking
                final bookings = snapshot.data!.docs;

                // Sắp xếp đơn hàng mới nhất lên đầu
                bookings.sort((a, b) {
                  Timestamp? timeA = a.data().toString().contains('createdAt')
                      ? a['createdAt'] as Timestamp?
                      : null;
                  Timestamp? timeB = b.data().toString().contains('createdAt')
                      ? b['createdAt'] as Timestamp?
                      : null;
                  if (timeA == null || timeB == null) return 0;
                  return timeB.compareTo(timeA); // Giảm dần
                });

                // 4. Vẽ danh sách các thẻ Booking
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final data = bookings[index].data() as Map<String, dynamic>;

                    // Parse dữ liệu
                    final hotelName = data['hotelName'] ?? 'Khách sạn chưa rõ';
                    final status = data['status'] ?? 'Đang xử lý';
                    final totalPrice = data['totalPrice'] ?? 0;
                    final checkInString = data['checkInDate'] ?? '';
                    final checkOutString = data['checkOutDate'] ?? '';

                    String dateRange = "Chưa rõ ngày";
                    if (checkInString.isNotEmpty && checkOutString.isNotEmpty) {
                      DateTime checkIn = DateTime.parse(checkInString);
                      DateTime checkOut = DateTime.parse(checkOutString);
                      dateRange =
                          "${DateFormat('dd/MM').format(checkIn)} - ${DateFormat('dd/MM/yyyy').format(checkOut)}";
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tên khách sạn & Trạng thái
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    hotelName,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: status.contains('Paid') ||
                                            status.contains('thanh toán')
                                        ? Colors.green[50]
                                        : Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: status.contains('Paid') ||
                                                status.contains('thanh toán')
                                            ? Colors.green
                                            : Colors.orange),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: status.contains('Paid') ||
                                              status.contains('thanh toán')
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),

                            // Ngày tháng & Số tiền
                            Row(
                              children: [
                                const Icon(Icons.calendar_month,
                                    color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Text(dateRange,
                                    style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.people_outline,
                                        color: Colors.grey, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                        '${data['guests'] ?? 1} khách, ${data['numberOfNights'] ?? 1} đêm',
                                        style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                                Text(
                                  NumberFormat.currency(
                                          locale: 'vi_VN', symbol: 'đ')
                                      .format(totalPrice),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue),
                                ),
                              ],
                            ),
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
}
