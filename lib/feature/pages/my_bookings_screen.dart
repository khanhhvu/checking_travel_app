import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  // =========================================================================
  // HÀM HIỂN THỊ VÉ ĐIỆN TỬ (E-TICKET) & MÃ QR
  // =========================================================================
  void _showTicketDialog(BuildContext context, Map<String, dynamic> data, String bookingId) {
    final hotelName = data['hotelName'] ?? 'Khách sạn chưa rõ';
    final guests = data['guests'] ?? 1;
    final checkInString = data['checkInDate'] ?? '';
    final checkOutString = data['checkOutDate'] ?? '';

    String dateRange = "Chưa rõ ngày";
    if (checkInString.isNotEmpty && checkOutString.isNotEmpty) {
      DateTime checkIn = DateTime.parse(checkInString);
      DateTime checkOut = DateTime.parse(checkOutString);
      dateRange = "${DateFormat('dd/MM').format(checkIn)} - ${DateFormat('dd/MM/yyyy').format(checkOut)}";
    }

    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Vé điện tử / E-Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 20),

                  // --- MÃ QR CODE GIẢ LẬP ---
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                        borderRadius: BorderRadius.circular(15)
                    ),
                    child: const Icon(Icons.qr_code_2, size: 150, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Text('Mã đặt phòng: ${bookingId.toUpperCase().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Divider(color: Colors.grey[300], thickness: 2),
                  ),

                  // --- THÔNG TIN ĐẶT PHÒNG ---
                  Text(hotelName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thời gian:', style: TextStyle(color: Colors.grey)),
                      Text(dateRange, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số khách:', style: TextStyle(color: Colors.grey)),
                      Text('$guests người', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Trạng thái:', style: TextStyle(color: Colors.grey)),
                      Text(
                          data['status'] ?? 'Đang xử lý',
                          style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      child: const Text('Đóng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Khách sạn đã đặt', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: currentUser == null
          ? const Center(child: Text('Vui lòng đăng nhập để xem lịch sử!', style: TextStyle(fontSize: 16)))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').where('userId', isEqualTo: currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu.'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.luggage_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Bạn chưa đặt khách sạn nào.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            );
          }

          final bookings = snapshot.data!.docs;

          // Sắp xếp đơn hàng mới nhất lên đầu
          bookings.sort((a, b) {
            Timestamp? timeA = a.data().toString().contains('createdAt') ? a['createdAt'] as Timestamp? : null;
            Timestamp? timeB = b.data().toString().contains('createdAt') ? b['createdAt'] as Timestamp? : null;
            if (timeA == null || timeB == null) return 0;
            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final doc = bookings[index];
              final data = doc.data() as Map<String, dynamic>;

              final hotelName = data['hotelName'] ?? 'Khách sạn chưa rõ';
              final status = data['status'] ?? 'Đang xử lý';
              final totalPrice = data['totalPrice'] ?? 0;
              final checkInString = data['checkInDate'] ?? '';
              final checkOutString = data['checkOutDate'] ?? '';

              String dateRange = "Chưa rõ ngày";
              if (checkInString.isNotEmpty && checkOutString.isNotEmpty) {
                DateTime checkIn = DateTime.parse(checkInString);
                DateTime checkOut = DateTime.parse(checkOutString);
                dateRange = "${DateFormat('dd/MM').format(checkIn)} - ${DateFormat('dd/MM/yyyy').format(checkOut)}";
              }

              // Đổi màu Label trạng thái
              bool isPaid = status.toLowerCase().contains('paid') || status.toLowerCase().contains('thanh toán');

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              hotelName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isPaid ? Colors.green[50] : Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isPaid ? Colors.green : Colors.orange),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: isPaid ? Colors.green[700] : Colors.orange[700],
                                fontSize: 12, fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Text(dateRange, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people_outline, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Text('${data['guests'] ?? 1} khách, ${data['numberOfNights'] ?? 1} đêm', style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          Text(
                            NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(totalPrice),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),

                      // ========================================================
                      // NÚT MỞ VÉ ĐIỆN TỬ
                      // ========================================================
                      if (isPaid) ...[
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showTicketDialog(context, data, doc.id),
                            icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                            label: const Text('Xem mã Check-in', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.blue),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                            ),
                          ),
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
}