import 'package:checking_travel_app/data/models/hotel_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  // Nhận toàn bộ dữ liệu từ màn hình Booking truyền sang
  final HotelModel hotel;
  final String customerName;
  final String phoneNumber;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guests;
  final int numberOfNights;
  final int totalPrice;

  const PaymentScreen({
    super.key,
    required this.hotel,
    required this.customerName,
    required this.phoneNumber,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guests,
    required this.numberOfNights,
    required this.totalPrice,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // 0: Thanh toán Online, 1: Thanh toán tại khách sạn
  int _selectedPaymentMethod = 0;
  bool _isProcessing = false;

  Future<void> _processPaymentAndSaveData() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Nếu chọn thanh toán Online, giả lập thời gian chờ ngân hàng xử lý 2 giây
      if (_selectedPaymentMethod == 0) {
        await Future.delayed(const Duration(seconds: 2));
      }

      // 2. Đẩy dữ liệu lên Firebase
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'khach_vang_lai',
        'hotelId': widget.hotel.id,
        'hotelName': widget.hotel.name,
        'customerName': widget.customerName,
        'phoneNumber': widget.phoneNumber,
        'checkInDate': widget.checkInDate.toIso8601String(),
        'checkOutDate': widget.checkOutDate.toIso8601String(),
        'numberOfNights': widget.numberOfNights,
        'guests': widget.guests,
        'totalPrice': widget.totalPrice,
        // Phân loại trạng thái và phương thức thanh toán cực kỳ chuyên nghiệp
        'paymentMethod': _selectedPaymentMethod == 0 ? 'Thẻ tín dụng / Online' : 'Tại khách sạn',
        'status': _selectedPaymentMethod == 0 ? 'Đã thanh toán (Paid)' : 'Chờ thanh toán (Pending)',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isProcessing = false;
      });

      // 3. Hiển thị Dialog Thành công
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.verified, color: Colors.green, size: 60),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Giao dịch thành công!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                _selectedPaymentMethod == 0
                    ? 'Bạn đã thanh toán trực tuyến thành công.'
                    : 'Phòng của bạn đã được giữ. Vui lòng thanh toán khi đến nơi.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Đóng Dialog và pop về tận màn hình tìm kiếm (pop 3 lần)
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Về trang chủ', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi giao dịch: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Thanh toán', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TỔNG QUAN SỐ TIỀN ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.blue[600], borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        const Text('Số tiền cần thanh toán', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(widget.totalPrice),
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text('Chọn phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  // --- OPTION 1: THANH TOÁN ONLINE ---
                  _buildPaymentOption(
                    index: 0,
                    title: 'Thanh toán trực tuyến (Thẻ Visa/Mastercard)',
                    icon: Icons.credit_card,
                    isSelected: _selectedPaymentMethod == 0,
                  ),

                  // Khung nhập thẻ giả lập (Chỉ hiện khi chọn Online)
                  if (_selectedPaymentMethod == 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.blue[100]!), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10))),
                        child: Column(
                          children: [
                            TextFormField(decoration: const InputDecoration(hintText: 'Số thẻ (VD: 4123 4567 8901 2345)', border: UnderlineInputBorder(), prefixIcon: Icon(Icons.payment))),
                            Row(
                              children: [
                                Expanded(child: TextFormField(decoration: const InputDecoration(hintText: 'MM/YY', border: UnderlineInputBorder()))),
                                const SizedBox(width: 15),
                                Expanded(child: TextFormField(decoration: const InputDecoration(hintText: 'CVV', border: UnderlineInputBorder()))),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // --- OPTION 2: THANH TOÁN TẠI KHÁCH SẠN ---
                  _buildPaymentOption(
                    index: 1,
                    title: 'Thanh toán tại khách sạn',
                    icon: Icons.storefront_outlined,
                    isSelected: _selectedPaymentMethod == 1,
                  ),
                ],
              ),
            ),
          ),

          // --- NÚT CHỐT ĐƠN Ở DƯỚI CÙNG ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))]),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPaymentAndSaveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedPaymentMethod == 0 ? Colors.blue : Colors.orange[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(
                    _selectedPaymentMethod == 0 ? 'Thanh toán ngay' : 'Xác nhận đặt phòng',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Widget tạo ra cái Card cho phép bấm chọn phương thức
  Widget _buildPaymentOption({required int index, required String title, required IconData icon, required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = index;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isSelected && index == 0 ? 0 : 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey[300]!, width: isSelected ? 2 : 1),
          borderRadius: isSelected && index == 0
              ? const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))
              : BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey[600], size: 30),
            const SizedBox(width: 15),
            Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.blue[800] : Colors.black87))),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}