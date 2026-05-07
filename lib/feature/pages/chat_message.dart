import 'package:checking_travel_app/feature/pages/chat_detail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatMessage extends StatefulWidget {
  const ChatMessage({super.key});

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
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
          'Tin nhắn',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: Colors.black, size: 24),
            onPressed: () {
              // TODO: Mở danh sách user để tạo chat mới
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- THANH TÌM KIẾM ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // --- DANH SÁCH TIN NHẮN THẬT (TỪ FIREBASE) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Tìm các phòng chat có chứa ID của mình, sắp xếp theo thời gian mới nhất
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('users', arrayContains: currentUser!.uid)
                  .orderBy('lastTimestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Chưa có đoạn chat nào.", style: TextStyle(color: Colors.grey)));
                }

                final chatRooms = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: chatRooms.length,
                  itemBuilder: (context, index) {
                    final roomData = chatRooms[index].data() as Map<String, dynamic>;

                    // 1. Lấy thông tin tin nhắn cuối cùng
                    final String lastMessage = roomData['lastMessage'] ?? 'Đã gửi một tin nhắn';
                    final Timestamp? timestamp = roomData['lastTimestamp'] as Timestamp?;
                    final String timeString = timestamp != null
                        ? DateFormat('HH:mm').format(timestamp.toDate())
                        : '';

                    // 2. Tìm ID của người kia (Khác ID của mình)
                    final List<dynamic> users = roomData['users'] ?? [];
                    final String otherUserId = users.firstWhere((id) => id != currentUser!.uid, orElse: () => "");

                    if (otherUserId.isEmpty) return const SizedBox();

                    // 3. Kéo thông tin Avatar và Tên của người kia từ bảng 'users'
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) return const SizedBox(); // Đang load ngầm

                        final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                        final String otherUserName = userData['displayName'] ?? userData['userName'] ?? 'Người dùng';
                        final String otherUserAvatar = userData['photoURL'] ?? userData['userAvatar'] ?? '';

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  receiverId: otherUserId,
                                  receiverName: otherUserName,
                                  receiverAvatar: otherUserAvatar,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: otherUserAvatar.isNotEmpty ? NetworkImage(otherUserAvatar) : null,
                                  child: otherUserAvatar.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            otherUserName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                                          ),
                                          Text(
                                            timeString,
                                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lastMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                      ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}