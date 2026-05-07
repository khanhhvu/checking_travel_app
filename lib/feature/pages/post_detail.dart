import 'package:checking_travel_app/data/models/post_model.dart';
import 'package:checking_travel_app/feature/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  // --- HÀM XỬ LÝ XÓA BÀI VIẾT ---
  Future<void> _deletePost(BuildContext context) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Xóa bài viết', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn xóa bài viết này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      // Hiện vòng xoay loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.red)),
      );

      try {
        // Xóa bài viết trên Firestore
        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

        // Tắt vòng xoay loading
        if (context.mounted) Navigator.pop(context);

        // Thông báo thành công và thoát ra ngoài
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa bài viết thành công!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ĐƯA FUTURE BUILDER RA NGOÀI CÙNG
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('posts').doc(postId).get(),
      builder: (context, snapshot) {
        // 1. Trạng thái đang tải
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colors.black)),
          );
        }

        // 2. Trạng thái lỗi hoặc bài viết không tồn tại
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white, elevation: 0,
              leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
            ),
            body: const Center(child: Text('Bài viết không tồn tại hoặc đã bị xóa.', style: TextStyle(color: Colors.grey))),
          );
        }

        try {
          final post = PostModel.fromFirestore(snapshot.data!);

          // KIỂM TRA QUYỀN SỞ HỮU BÀI VIẾT
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          final isMyPost = currentUserId == post.userId; // So sánh ID

          // 3. Trạng thái tải thành công -> Vẽ giao diện
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Bài viết', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              centerTitle: true,
              actions: [
                // NÚT 3 CHẤM (CHỈ HIỆN KHI LÀ BÀI CỦA MÌNH)
                if (isMyPost)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost(context);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Xóa bài viết', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            body: SingleChildScrollView(
              child: PostItemWidget(post: post),
            ),
          );
        } catch (e) {
          return Scaffold(body: Center(child: Text('Lỗi tải bài viết: $e')));
        }
      },
    );
  }
}