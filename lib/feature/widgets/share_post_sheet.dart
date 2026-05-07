import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SharePostSheet extends StatefulWidget {
  final String postId;

  const SharePostSheet({super.key, required this.postId});

  @override
  State<SharePostSheet> createState() => _SharePostSheetState();
}

class _SharePostSheetState extends State<SharePostSheet> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> _eligibleUsers = [];
  bool _isLoading = true;
  Set<String> _sentUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadEligibleUsers();
  }

  // --- THUẬT TOÁN TÌM NGƯỜI ĐỦ ĐIỀU KIỆN CHIA SẺ ---
  Future<void> _loadEligibleUsers() async {
    if (currentUser == null) return;
    String myUid = currentUser!.uid;
    Set<String> targetUids = {}; // Dùng Set để tự động lọc trùng lặp

    try {
      // 1. Tìm những người Cùng Follow Nhau
      DocumentSnapshot myDoc =
          await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      if (myDoc.exists) {
        Map<String, dynamic> data = myDoc.data() as Map<String, dynamic>? ?? {};
        List following = data['following'] ?? [];
        List followers = data['followers'] ?? [];

        for (var uid in following) {
          if (followers.contains(uid)) {
            targetUids.add(uid);
          }
        }
      }

      // 2. Tìm những người Đã Từng Nhắn Tin
      QuerySnapshot chatDocs = await FirebaseFirestore.instance
          .collection('chats')
          .where('users', arrayContains: myUid)
          .get();

      for (var doc in chatDocs.docs) {
        List users = (doc.data() as Map<String, dynamic>)['users'] ?? [];
        String otherUid =
            users.firstWhere((id) => id != myUid, orElse: () => "");
        if (otherUid.isNotEmpty) {
          targetUids.add(otherUid); // Thêm vào danh sách
        }
      }

      // 3. Truy xuất thông tin Tên và Avatar để hiển thị
      List<Map<String, dynamic>> loadedUsers = [];
      for (var uid in targetUids) {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>? ?? {};
          loadedUsers.add({
            'uid': uid,
            'name':
                userData['displayName'] ?? userData['userName'] ?? 'Người dùng',
            'avatar': userData['photoURL'] ?? userData['userAvatar'] ?? '',
          });
        }
      }

      if (mounted) {
        setState(() {
          _eligibleUsers = loadedUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm tạo ID phòng chat duy nhất
  String _getChatRoomId(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "${b}_$a";
    } else {
      return "${a}_$b";
    }
  }

  // --- HÀM XỬ LÝ KHI BẤM NÚT GỬI ---
  // --- HÀM XỬ LÝ KHI BẤM NÚT GỬI ---
  Future<void> _sendShare(String targetUid) async {
    if (currentUser == null) return;
    String myUid = currentUser!.uid;

    // Đổi giao diện thành "Đã gửi" ngay lập tức cho mượt
    setState(() {
      _sentUserIds.add(targetUid);
    });

    String chatRoomId = _getChatRoomId(myUid, targetUid);

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': myUid,
        'receiverId': targetUid,
        'message': "Mình vừa chia sẻ một chuyến đi thú vị!",
        // Bỏ dòng [Bài viết ID] đi cho sạch đẹp
        'type': 'share_post',
        // THẺ QUAN TRỌNG NHẤT ĐỂ BIẾN THÀNH CARD
        'postId': widget.postId,
        // LƯU ID BÀI VIẾT VÀO ĐÚNG TRƯỜNG
        'postImage': '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
        'users': [myUid, targetUid],
        'lastMessage': "Đã chia sẻ một bài viết",
        'lastTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi chia sẻ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10))),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Chia sẻ bài viết',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black))
                : _eligibleUsers.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'Bạn chưa có người theo dõi chung hoặc chưa nhắn tin với ai.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _eligibleUsers.length,
                        itemBuilder: (context, index) {
                          final user = _eligibleUsers[index];
                          final bool isSent =
                              _sentUserIds.contains(user['uid']);

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: user['avatar'].isNotEmpty
                                  ? NetworkImage(user['avatar'])
                                  : null,
                              child: user['avatar'].isEmpty
                                  ? const Icon(Icons.person, color: Colors.grey)
                                  : null,
                            ),
                            title: Text(user['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            trailing: ElevatedButton(
                              onPressed:
                                  isSent ? null : () => _sendShare(user['uid']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isSent ? Colors.grey[300] : Colors.blue,
                                foregroundColor:
                                    isSent ? Colors.grey[600] : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                              child: Text(isSent ? 'Đã gửi' : 'Gửi'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
