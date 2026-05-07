import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Thêm thư viện Auth
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class FindGuideScreen extends StatefulWidget {
  const FindGuideScreen({super.key});

  @override
  State<FindGuideScreen> createState() => _FindGuideScreenState();
}

class _FindGuideScreenState extends State<FindGuideScreen> {
  List<String> _provinces = ['Tất cả khu vực'];
  String _selectedProvince = 'Tất cả khu vực';

  final List<String> _sortOptions = ['Uy tín nhất', 'Nhiều lượt đặt', 'Giá thấp - cao', 'Giá cao - thấp'];
  String _selectedSort = 'Uy tín nhất';

  @override
  void initState() {
    super.initState();
    _fetchProvinces();
  }

  Future<void> _fetchProvinces() async {
    try {
      final response = await http.get(Uri.parse('https://provinces.open-api.vn/api/?depth=1'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _provinces.addAll(data.map((p) => p['name'].toString()).toList());
        });
      }
    } catch (e) {
      print("Lỗi tải tỉnh thành: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy ID người dùng hiện tại để check điều kiện "Tự thuê chính mình"
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tìm Hướng dẫn viên', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // --- BỘ LỌC ---
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 5))]),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true, value: _selectedProvince, icon: const Icon(Icons.location_on, color: Colors.blue, size: 20),
                        items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setState(() => _selectedProvince = val!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true, value: _selectedSort, icon: const Icon(Icons.sort, color: Colors.blue, size: 20),
                        items: _sortOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) => setState(() => _selectedSort = val!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- DANH SÁCH HDV ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('guides').where('status', isEqualTo: 'Approved').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState('Chưa có Hướng dẫn viên nào.');

                List<QueryDocumentSnapshot> guides = snapshot.data!.docs;
                if (_selectedProvince != 'Tất cả khu vực') {
                  guides = guides.where((doc) => (doc.data() as Map<String, dynamic>)['province'] == _selectedProvince).toList();
                }
                if (guides.isEmpty) return _buildEmptyState('Không tìm thấy HDV nào tại $_selectedProvince.');

                guides.sort((a, b) {
                  final dA = a.data() as Map<String, dynamic>; final dB = b.data() as Map<String, dynamic>;
                  double rA = (dA['rating'] ?? 5.0).toDouble(); double rB = (dB['rating'] ?? 5.0).toDouble();
                  int bA = dA['bookings'] ?? 0; int bB = dB['bookings'] ?? 0;
                  int pA = dA['pricePerDay'] ?? 500000; int pB = dB['pricePerDay'] ?? 500000;
                  switch (_selectedSort) {
                    case 'Uy tín nhất': int c = rB.compareTo(rA); return c != 0 ? c : bB.compareTo(bA);
                    case 'Nhiều lượt đặt': return bB.compareTo(bA);
                    case 'Giá thấp - cao': return pA.compareTo(pB);
                    case 'Giá cao - thấp': return pB.compareTo(pA);
                    default: return 0;
                  }
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: guides.length,
                  itemBuilder: (context, index) {
                    final data = guides[index].data() as Map<String, dynamic>;
                    final guideId = data['userId'] ?? guides[index].id;
                    final fullName = data['fullName'] ?? 'Chưa rõ tên';
                    final province = data['province'] ?? 'Chưa rõ khu vực';
                    final int price = data['pricePerDay'] ?? 500000;

                    // Kiểm tra xem User đang đăng nhập có đang xem chính hồ sơ của mình không
                    final bool isSelf = guideId == currentUserId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(radius: 25, backgroundColor: Colors.blue[100], child: Text(fullName[0].toUpperCase(), style: const TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.bold))),
                                const SizedBox(width: 15),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text(province, style: const TextStyle(color: Colors.grey)),
                                ])),
                              ],
                            ),
                            const Divider(height: 25),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price) + ' / ngày', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),

                                // LOGIC HIỂN THỊ NÚT BẤM
                                isSelf
                                    ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                                  child: Text('Hồ sơ của bạn', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                )
                                    : ElevatedButton(
                                  onPressed: () async {
                                    if (currentUserId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để thuê HDV!')));
                                      return;
                                    }

                                    // Bật loading
                                    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

                                    try {
                                      // Đẩy Booking Request lên Firebase
                                      await FirebaseFirestore.instance.collection('tour_requests').add({
                                        'guideId': guideId,
                                        'guideName': fullName,
                                        'touristId': currentUserId,
                                        'touristName': FirebaseAuth.instance.currentUser?.email ?? 'Khách hàng', // Lấy email tạm làm tên
                                        'price': price,
                                        'status': 'Pending', // Đang chờ duyệt
                                        'createdAt': FieldValue.serverTimestamp(),
                                      });

                                      if (context.mounted) Navigator.pop(context); // Tắt loading

                                      // Báo thành công
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Đã gửi yêu cầu thuê $fullName! Vui lòng chờ xác nhận.'),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                  child: const Text('Thuê ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 60, color: Colors.grey[400]), const SizedBox(height: 16), Text(message, style: TextStyle(color: Colors.grey[600]))]));
  }
}