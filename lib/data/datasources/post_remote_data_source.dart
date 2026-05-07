import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

class PostRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  PostRemoteDataSource(this.firestore, this.firebaseAuth);

  Stream<List<PostModel>> getPostsStream() {
    return firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    });
  }

  Future<String?> _uploadSingleImage(String imagePath) async {
    const String apiKey = 'f32493619f4b20d32133074a192285f1';
    const String apiUrl = 'https://api.imgbb.com/1/upload';

    try {
      File imageFile = File(imagePath);
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
      print('Lỗi upload ảnh: $e');
    }
    return null;
  }

  Future<void> createPost(String caption, List<String> imagePaths) async {
    User? currentUser = firebaseAuth.currentUser;
    if (currentUser == null) throw Exception("Vui lòng đăng nhập để đăng bài.");

    List<String> imageUrls = [];

    // Tải tất cả ảnh lên
    for (String path in imagePaths) {
      String? url = await _uploadSingleImage(path);
      if (url != null) imageUrls.add(url);
    }

    // Đẩy lên Firestore
    await firestore.collection('posts').add({
      'userId': currentUser.uid,
      'userName': currentUser.displayName ?? 'Người dùng',
      'userAvatar': currentUser.photoURL ?? '',
      'caption': caption,
      'imageUrls': imageUrls,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<PostModel>> getUserPostsStream(String userId) {
    return firestore
        .collection('posts')
        .where('userId', isEqualTo: userId) // Lọc đúng bài của user này
        .orderBy('timestamp', descending: true) // Xếp mới nhất lên đầu
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    });
  }
  Future<void> toggleLike(String postId, bool isLiked) async {
    User? user = firebaseAuth.currentUser;
    if (user == null) return;

    DocumentReference postRef = firestore.collection('posts').doc(postId);

    if (isLiked) {
      // Nếu trạng thái là Thích -> Thêm ID của mình vào mảng likes
      await postRef.update({
        'likes': FieldValue.arrayUnion([user.uid])
      });
    } else {
      // Nếu trạng thái là Bỏ thích -> Xóa ID của mình khỏi mảng likes
      await postRef.update({
        'likes': FieldValue.arrayRemove([user.uid])
      });
    }
  }
}
