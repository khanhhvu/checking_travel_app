import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'guide_dashboard_screen.dart';

class GuideRegistrationScreen extends StatefulWidget {
  const GuideRegistrationScreen({super.key});

  @override
  State<GuideRegistrationScreen> createState() =>
      _GuideRegistrationScreenState();
}

class _GuideRegistrationScreenState extends State<GuideRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  DateTime? _dob;
  bool _isSubmitting = false;

  List<dynamic> _provinces = [];
  String? _selectedProvince;
  bool _isLoadingProvinces = true;

  final List<String> _availableSkills = [
    'Food tour',
    'Chụp ảnh',
    'Lịch sử - Văn hóa',
    'Ngoại ngữ',
    'Phượt xe máy'
  ];
  final List<String> _selectedSkills = [];

  @override
  void initState() {
    super.initState();
    _fetchProvinces();
  }

  Future<void> _fetchProvinces() async {
    try {
      final response = await http
          .get(Uri.parse('https://provinces.open-api.vn/api/?depth=1'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _provinces = data;
          _isLoadingProvinces = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingProvinces = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (_dob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng chọn ngày sinh!')));
        return;
      }
      if (_selectedProvince == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng chọn khu vực!')));
        return;
      }
      if (_selectedSkills.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Vui lòng chọn ít nhất 1 chuyên môn!')));
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) throw Exception('Chưa đăng nhập');

        int price = int.tryParse(_priceController.text) ?? 500000;

        await FirebaseFirestore.instance
            .collection('guides')
            .doc(currentUser.uid)
            .set({
          'userId': currentUser.uid,
          'fullName': _nameController.text,
          'avatarUrl': currentUser.photoURL ?? '',
          'dob': _dob!.toIso8601String(),
          'idCard': _idCardController.text,
          'phone': _phoneController.text,
          'province': _selectedProvince,
          'address': _addressController.text,
          'bio': _bioController.text,
          'skills': _selectedSkills,
          'pricePerDay': price,
          'status': 'Approved',
          'rating': 5.0,
          'bookings': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({
          'isGuide': true,
        }, SetOptions(merge: true));

        setState(() => _isSubmitting = false);
        if (!mounted) return;
        _showSuccessDialog();
      } catch (e) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.verified_user, color: Colors.green, size: 60),
        content: const Text('Đăng ký thành công!', textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GuideDashboardScreen()));
              },
              child: const Text('Vào Kênh HDV ngay'),
            ),
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
        title: const Text('Đăng ký Hướng dẫn viên',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoadingProvinces
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thông tin cá nhân',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    TextFormField(
                        controller: _nameController,
                        decoration: _buildInput(
                            'Họ tên (theo CCCD)', Icons.person_outline),
                        validator: (v) => v!.isEmpty ? 'Nhập họ tên' : null),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _selectedProvince,
                      decoration:
                          _buildInput('Khu vực hoạt động', Icons.map_outlined),
                      items: _provinces
                          .map((province) => DropdownMenuItem<String>(
                              value: province['name'],
                              child: Text(province['name'])))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedProvince = val),
                      validator: (v) => v == null ? 'Chọn tỉnh thành' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInput('Mức giá thuê mỗi ngày (VNĐ)',
                            Icons.monetization_on_outlined),
                        validator: (v) => v!.isEmpty
                            ? 'Vui lòng nhập mức giá mong muốn'
                            : null),
                    const SizedBox(height: 15),
                    TextFormField(
                        controller: _idCardController,
                        keyboardType: TextInputType.number,
                        decoration:
                            _buildInput('Số CCCD', Icons.badge_outlined),
                        validator: (v) =>
                            v!.length < 9 ? 'CCCD không hợp lệ' : null),
                    const SizedBox(height: 15),
                    TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _buildInput(
                            'Số điện thoại liên hệ', Icons.phone_outlined),
                        validator: (v) => v!.length < 10
                            ? 'Số điện thoại không hợp lệ'
                            : null),
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey)),
                        child: Row(children: [
                          const Icon(Icons.cake_outlined, color: Colors.grey),
                          const SizedBox(width: 10),
                          Text(_dob == null
                              ? 'Ngày sinh'
                              : DateFormat('dd/MM/yyyy').format(_dob!))
                        ]),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text('Thế mạnh chuyên môn',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10.0,
                      children: _availableSkills.map((skill) {
                        final isSelected = _selectedSkills.contains(skill);
                        return FilterChip(
                          label: Text(skill,
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87)),
                          selected: isSelected,
                          selectedColor: Colors.blue,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedSkills.add(skill);
                              } else {
                                _selectedSkills.remove(skill);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 25),
                    const Text('Giới thiệu bản thân',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            hintText: 'Kể về kinh nghiệm của bạn...',
                            border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Hãy viết gì đó' : null),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRegistration,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15))),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Hoàn tất đăng ký',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _buildInput(String label, IconData icon) {
    return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white);
  }
}
