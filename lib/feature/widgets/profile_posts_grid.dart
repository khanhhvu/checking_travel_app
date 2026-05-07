import 'package:checking_travel_app/feature/pages/post_detail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePostsGrid extends StatelessWidget {
  final String userId; // ID của người dùng cần xem bài viết

  const ProfilePostsGrid({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Lắng nghe collection bài viết của user này trên Firebase
      // Bạn cần điều chỉnh query cho đúng với cấu trúc Database của bạn
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text("Chưa có bài viết nào.", style: TextStyle(color: Colors.grey))),
            ),
          );
        }

        final posts = snapshot.data!.docs;

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 1.0,
            crossAxisSpacing: 1.0,
            childAspectRatio: 1.0,
          ),
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              final String postId = posts[index].id;

              // Giả sử dữ liệu bài viết có mảng 'images' và lấy ảnh đầu tiên
              final List<dynamic> images = post['images'] ?? [];
              final String imageUrl = images.isNotEmpty ? images[0] : '';

              return GestureDetector(
                onTap: () {
                  // --- CLICK VÀO ẢNH -> MỞ CHI TIẾT BÀI VIẾT CỦA BẠN ---
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(postId: postId),
                    ),
                  );
                },
                child: Container(
                  color: Colors.grey[200], // Màu nền khi ảnh đang load
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover, // Ép ảnh lấp đầy ô vuông
                    errorBuilder: (c, e, s) => const Icon(Icons.error_outline),
                  )
                      : const Icon(Icons.image_outlined, color: Colors.grey),
                ),
              );
            },
            childCount: posts.length,
          ),
        );
      },
    );
  }
}