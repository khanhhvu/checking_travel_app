import 'package:checking_travel_app/feature/pages/post_detail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  State<Favorite> createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Hoạt động',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Lắng nghe liên tục thư mục 'notifications' của mình, xếp mới nhất lên đầu
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Chưa có thông báo nào.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index].data() as Map<String, dynamic>;
              final String type = notif['type'] ?? '';
              final String senderName = notif['senderName'] ?? 'Ai đó';
              final String senderAvatar = notif['senderAvatar'] ?? '';
              final Timestamp? timestamp = notif['timestamp'] as Timestamp?;

              String timeString = timestamp != null
                  ? DateFormat('dd/MM HH:mm').format(timestamp.toDate())
                  : 'Vừa xong';

              // Xử lý nội dung hiển thị dựa trên type (like hay comment)
              // ... (Các code ở trên giữ nguyên) ...

              // Xử lý nội dung hiển thị dựa trên type
              String actionText = '';
              Widget icon = const SizedBox();

              if (type == 'like') {
                actionText = 'đã thích bài viết của bạn.';
                icon = const Icon(Icons.favorite, color: Colors.red, size: 16);
              } else if (type == 'comment') {
                final String commentContent = notif['content'] ?? '';
                actionText = 'đã bình luận: "$commentContent"';
                icon = const Icon(Icons.chat_bubble, color: Colors.blue, size: 16);
              } else if (type == 'follow') {
                actionText = 'đã bắt đầu theo dõi bạn.';
                icon = const Icon(Icons.person_add, color: Colors.green, size: 16);
              }
              // --- THÊM PHẦN XỬ LÝ CHO TOUR Ở ĐÂY ---
              else if (type == 'tour_accepted') {
                actionText = 'đã CHẤP NHẬN yêu cầu dẫn tour của bạn. Hãy nhắn tin ngay!';
                icon = const Icon(Icons.check_circle, color: Colors.green, size: 16);
              } else if (type == 'tour_declined') {
                actionText = 'rất tiếc đã từ chối yêu cầu dẫn tour của bạn.';
                icon = const Icon(Icons.cancel, color: Colors.red, size: 16);
              }

              return InkWell(
                onTap: () {
                  // NẾU LÀ THÔNG BÁO VỀ TOUR
                  if (type == 'tour_accepted' || type == 'tour_declined') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chuyển đến Danh sách Khách sạn / Tour của bạn...')),
                    );
                  }
                  // NẾU LÀ THÔNG BÁO VỀ BÀI VIẾT (Like, Cmt)
                  else {
                    final String targetPostId = notif['postId'] ?? '';
                    if (targetPostId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostDetailScreen(postId: targetPostId),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Không tìm thấy bài viết!')),
                      );
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: senderAvatar.isNotEmpty ? NetworkImage(senderAvatar) : null,
                            child: senderAvatar.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: icon, // Icon nhỏ ở góc avatar (Tim đỏ, Chat xanh)
                            ),
                          )
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Nội dung thông báo
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black, fontSize: 14, height: 1.4),
                                children: [
                                  TextSpan(text: senderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const TextSpan(text: ' '),
                                  TextSpan(text: actionText),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(timeString, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          ],
                        ),
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