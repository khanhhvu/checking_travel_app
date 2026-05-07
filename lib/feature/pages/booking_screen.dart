import 'package:checking_travel_app/data/models/hotel_model.dart';
import 'package:checking_travel_app/feature/pages/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class BookingScreen extends StatefulWidget {
  final HotelModel hotel; // Dữ liệu khách sạn truyền từ trang chi tiết sang

  const BookingScreen({super.key, required this.hotel});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _guests = 1;

  // ==========================================
  // CÁC HÀM TÍNH TOÁN TỔNG TIỀN
  // ==========================================
  int get _numberOfNights {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    return _checkOutDate!.difference(_checkInDate!).inDays;
  }

  int get _pricePerNight {
    String numberString = widget.hotel.price.replaceAll(RegExp(r'[^0-9]'), '');
    if (numberString.isEmpty) return 0;
    return int.parse(numberString);
  }

  int get _totalPrice {
    return _numberOfNights * _pricePerNight;
  }

  // ==========================================
  // HÀM CHỌN NGÀY
  // ==========================================
  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn
          ? (_checkInDate ?? DateTime.now())
          : (_checkOutDate ?? (_checkInDate ?? DateTime.now()).add(const Duration(days: 1))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          if (_checkOutDate != null && _checkOutDate!.compareTo(_checkInDate!) <= 0) {
            _checkOutDate = _checkInDate!.add(const Duration(days: 1));
          }
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  // ==========================================
  // HÀM CHUYỂN SANG TRANG THANH TOÁN
  // ==========================================
  void _submitBooking() {
    if (_formKey.currentState!.validate()) {
      if (_checkInDate == null || _checkOutDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ngày nhận và trả phòng!'), backgroundColor: Colors.red),
        );
        return;
      }

      // Đẩy toàn bộ dữ liệu thu thập được sang PaymentScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            hotel: widget.hotel,
            customerName: _nameController.text,
            phoneNumber: _phoneController.text,
            checkInDate: _checkInDate!,
            checkOutDate: _checkOutDate!,
            guests: _guests,
            numberOfNights: _numberOfNights,
            totalPrice: _totalPrice,
          ),
        ),
      );
    }
  }

  // ==========================================
  // GIAO DIỆN CHÍNH
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Xác nhận đặt phòng', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(widget.hotel.imageUrl, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.grey)),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.hotel.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 5),
                          Text(widget.hotel.price, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text(' / đêm', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              const Text('Thông tin liên hệ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Họ và tên', prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white,
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại', prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white,
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
              ),

              const SizedBox(height: 25),
              const Text('Chi tiết đặt phòng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: _buildDateCard('Nhận phòng', _checkInDate),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (_checkInDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ngày nhận phòng trước!')));
                        } else {
                          _selectDate(context, false);
                        }
                      },
                      child: _buildDateCard('Trả phòng', _checkOutDate),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[400]!)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(children: [Icon(Icons.people_outline, color: Colors.grey), SizedBox(width: 10), Text('Số khách', style: TextStyle(fontSize: 16))]),
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() { if (_guests > 1) _guests--; })),
                        Text('$_guests', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() { if (_guests < 10) _guests++; })),
                      ],
                    )
                  ],
                ),
              ),

              if (_numberOfNights > 0) ...[
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue[100]!)
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Giá phòng ($_numberOfNights đêm)', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                          Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_totalPrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const Divider(height: 20, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_totalPrice),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: const Text('Tiến hành thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard(String title, DateTime? date) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[400]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 5),
          Text(
            date == null ? 'Chọn ngày' : DateFormat('dd/MM/yyyy').format(date),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: date == null ? Colors.grey : Colors.black),
          ),
        ],
      ),
    );
  }
}