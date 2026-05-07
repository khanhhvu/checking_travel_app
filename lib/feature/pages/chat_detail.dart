import 'package:checking_travel_app/feature/pages/post_detail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDetailScreen extends StatefulWidget {
  final String receiverId; // ID của người mình muốn nhắn
  final String receiverName;
  final String receiverAvatar;

  const ChatDetailScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late String chatRoomId;

  @override
  void initState() {
    super.initState();
    // Tạo ID phòng chat duy nhất cho 2 người (để A nhắn B hay B nhắn A đều vào chung 1 phòng)
    chatRoomId = _getChatRoomId(currentUser!.uid, widget.receiverId);
  }

  // Thuật toán gộp 2 UID thành 1 ID phòng chat duy nhất bằng cách sắp xếp theo bảng chữ cái
  String _getChatRoomId(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "${b}_$a";
    } else {
      return "${a}_$b";
    }
  }

  // Hàm gửi tin nhắn
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String message = _messageController.text.trim();
    _messageController.clear();

    // 1. Thêm tin nhắn vào subcollection 'messages'
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUser!.uid,
      'receiverId': widget.receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Cập nhật tin nhắn mới nhất ra ngoài phòng chat (để màn hình Inbox của bạn đọc được)
    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
      'users': [currentUser!.uid, widget.receiverId],
      'lastMessage': message,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.receiverAvatar.isNotEmpty ? NetworkImage(widget.receiverAvatar) : null,
              child: widget.receiverAvatar.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 10),
            Text(
              widget.receiverName,
              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // --- KHU VỰC HIỂN THỊ TIN NHẮN ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true) // Tin mới nhất ở dưới cùng
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Hãy gửi lời chào đầu tiên!", style: TextStyle(color: Colors.grey)));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Đẩy list từ dưới lên giống Messenger
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var data = messages[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUser?.uid;

                    return _buildMessageBubble(data, isMe);
                  },
                );
              },
            ),
          ),

          // --- KHU VỰC NHẬP TIN NHẮN ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Nhắn tin...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI của 1 bong bóng chat
  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    String message = data['message'] ?? '';
    String type = data['type'] ?? 'text';
    String postId = data['postId'] ?? '';
    String postImage = data['postImage'] ?? '';

    // --- THUẬT TOÁN BẮT LINK TỰ ĐỘNG (Dành cho dữ liệu cũ hoặc gõ tay) ---
    if (message.contains('[Bài viết ID:')) {
      type = 'share_post'; // Ép nó thành giao diện thẻ Card
      // Trích xuất chính xác đoạn ID nằm trong ngoặc vuông
      final match = RegExp(r'\[Bài viết ID:\s*(.*?)\]').firstMatch(message);
      if (match != null) {
        postId = match.group(1) ?? postId;
      }
    }

    // 1. NẾU LÀ TIN NHẮN CHIA SẺ BÀI VIẾT (Giao diện Thẻ Card)
    if (type == 'share_post' && postId.isNotEmpty) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {
            // Bay thẳng sang chi tiết bài viết
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PostDetailScreen(postId: postId)),
            );
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.65,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue[50] : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isMe ? Colors.blue[200]! : Colors.grey[300]!),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh bài viết
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: postImage.isNotEmpty
                      ? Image.network(postImage, height: 140, width: double.infinity, fit: BoxFit.cover)
                      : Container(
                      height: 100, width: double.infinity,
                      color: Colors.grey[200],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, color: Colors.grey, size: 30),
                          SizedBox(height: 4),
                          Text('Bài viết', style: TextStyle(color: Colors.grey, fontSize: 12))
                        ],
                      )
                  ),
                ),
                // Dòng chữ mô tả
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          message.replaceAll(RegExp(r'\[Bài viết ID:.*?\]'), '').trim(), // Xóa dòng ID lộn xộn đi cho đẹp
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.touch_app, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text('Chạm để xem bài viết', style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    // 2. NẾU LÀ TIN NHẮN CHỮ BÌNH THƯỜNG
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
          boxShadow: [
            if (!isMe) BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 3, offset: const Offset(0, 1))
          ],
        ),
        child: Text(
          message,
          style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 15),
        ),
      ),
    );
  }
}