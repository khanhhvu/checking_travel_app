import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class EditProfileSheet extends StatefulWidget {
  final User currentUser;
  const EditProfileSheet({super.key, required this.currentUser});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  File? _selectedAvatar;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.displayName);
    _bioController = TextEditingController(text: '');

    // Lấy bio hiện tại từ Firestore
    FirebaseFirestore.instance.collection('users').doc(widget.currentUser.uid).get().then((doc) {
      if (doc.exists && mounted) {
        setState(() {
          _bioController.text = doc.data()?['bio'] ?? '';
        });
      }
    });
  }

  // --- HÀM UPLOAD ẢNH LÊN IMGBB ---
  Future<String?> _uploadAvatarToImgBB(File imageFile) async {
    const String apiKey = 'f32493619f4b20d32133074a192285f1'; // API Key của bạn
    const String apiUrl = 'https://api.imgbb.com/1/upload';

    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      var response = await http.post(
        Uri.parse(apiUrl),
        body: {'key': apiKey, 'image': base64Image},
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        return jsonResponse['data']['url'];
      }
    } catch (e) {
      print('Lỗi upload avatar: $e');
    }
    return null;
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      String? newAvatarUrl = widget.currentUser.photoURL;

      // 1. Nếu có chọn ảnh mới, upload lên trước để lấy link
      if (_selectedAvatar != null) {
        String? uploadedUrl = await _uploadAvatarToImgBB(_selectedAvatar!);
        if (uploadedUrl != null) {
          newAvatarUrl = uploadedUrl;
        }
      }

      // 2. Cập nhật Firebase Auth (Tên và Ảnh)
      await widget.currentUser.updateDisplayName(_nameController.text.trim());
      if (newAvatarUrl != null) {
        await widget.currentUser.updatePhotoURL(newAvatarUrl);
      }

      // 3. Cập nhật Firestore 'users' (Lưu Bio và Avatar)
      await FirebaseFirestore.instance.collection('users').doc(widget.currentUser.uid).set({
        'displayName': _nameController.text.trim(),
        'photoURL': newAvatarUrl,
        'bio': _bioController.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 4. Cập nhật tất cả bài viết cũ (Đồng bộ ảnh đại diện và tên mới)
      var postsQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.currentUser.uid)
          .get();

      var batch = FirebaseFirestore.instance.batch();
      for (var doc in postsQuery.docs) {
        batch.update(doc.reference, {
          'userName': _nameController.text.trim(),
          'userAvatar': newAvatarUrl,
        });
      }
      await batch.commit();

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildAvatarPicker(),
                    const SizedBox(height: 30),
                    _buildTextField('Tên', _nameController),
                    const SizedBox(height: 20),
                    _buildTextField('Tiểu sử', _bioController, maxLines: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.black))),
          const Text('Chỉnh sửa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(onPressed: _saveProfile, child: const Text('Lưu', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: () async {
        final image = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (image != null) setState(() => _selectedAvatar = File(image.path));
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: _selectedAvatar != null
                ? FileImage(_selectedAvatar!) as ImageProvider
                : (widget.currentUser.photoURL != null ? NetworkImage(widget.currentUser.photoURL!) : null),
            child: (_selectedAvatar == null && widget.currentUser.photoURL == null) ? const Icon(Icons.person, size: 50) : null,
          ),
          const Icon(Icons.camera_alt, color: Colors.white70, size: 30),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}