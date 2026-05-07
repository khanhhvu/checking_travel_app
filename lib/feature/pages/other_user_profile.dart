import 'package:checking_travel_app/domain/entities/post_entity.dart';
import 'package:checking_travel_app/feature/bloc/profile/profile_bloc.dart';
import 'package:checking_travel_app/feature/pages/chat_detail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OtherUserProfile extends StatefulWidget {
  final String userId;
  final String userName;
  final String userAvatar;

  const OtherUserProfile({
    super.key,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });

  @override
  State<OtherUserProfile> createState() => _OtherUserProfileState();
}

class _OtherUserProfileState extends State<OtherUserProfile> {
  bool _isFollowing = false;
  int _followerCount = 0;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Tải bài viết
    context.read<ProfileBloc>().add(LoadProfilePosts(widget.userId));

    // Lắng nghe dữ liệu người dùng này từ Firebase (Realtime)
    _listenToFollowers();
  }

  // --- HÀM 1: LẮNG NGHE SỐ NGƯỜI THEO DÕI THỰC TẾ ---
  void _listenToFollowers() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        // Lấy mảng followers (Nếu chưa có thì gán mảng rỗng [])
        List<dynamic> followers = doc.data()!['followers'] ?? [];

        if (mounted) {
          setState(() {
            _followerCount = followers.length; // Số lượng = Độ dài của mảng
            // Kiểm tra xem ID của mình đã nằm trong mảng của họ chưa
            if (currentUser != null) {
              _isFollowing = followers.contains(currentUser!.uid);
            }
          });
        }
      }
    });
  }

  // --- HÀM 2: XỬ LÝ KHI BẤM NÚT THEO DÕI / BỎ THEO DÕI ---
  Future<void> _toggleFollow() async {
    if (currentUser == null) return;

    final String myUid = currentUser!.uid;
    final String targetUid = widget.userId;

    // Tạm thời đổi UI trước cho mượt
    setState(() {
      _isFollowing = !_isFollowing;
      _followerCount += _isFollowing ? 1 : -1;
    });

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference meRef = FirebaseFirestore.instance.collection('users').doc(myUid);
      DocumentReference targetRef = FirebaseFirestore.instance.collection('users').doc(targetUid);

      if (_isFollowing) {
        batch.set(meRef, {'following': FieldValue.arrayUnion([targetUid])}, SetOptions(merge: true));
        batch.set(targetRef, {'followers': FieldValue.arrayUnion([myUid])}, SetOptions(merge: true));
      } else {
        batch.set(meRef, {'following': FieldValue.arrayRemove([targetUid])}, SetOptions(merge: true));
        batch.set(targetRef, {'followers': FieldValue.arrayRemove([myUid])}, SetOptions(merge: true));
      }

      await batch.commit(); // Gửi lệnh lưu
      print("LƯU FOLLOW THÀNH CÔNG LÊN FIREBASE!");

    } catch (e) {
      // Nếu Firebase báo lỗi -> Lập tức quay xe (Hoàn tác UI)
      setState(() {
        _isFollowing = !_isFollowing;
        _followerCount += _isFollowing ? 1 : -1;
      });

      // Bắn thẳng lỗi ra màn hình cho bạn xem
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không lưu được: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.black),
                onPressed: () {}),
          ],
        ),
        body: Column(
          children: [
            // --- THÔNG TIN USER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.userName.replaceAll(' ', '').toLowerCase(),
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            // --- HIỂN THỊ SỐ NGƯỜI THEO DÕI THẬT ---
                            Text(
                              '$_followerCount người theo dõi',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: widget.userAvatar.isNotEmpty
                            ? NetworkImage(widget.userAvatar)
                            : null,
                        child: widget.userAvatar.isEmpty
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Nút tương tác
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          // GỌI HÀM XỬ LÝ THEO DÕI Ở ĐÂY
                          onPressed: _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isFollowing ? Colors.white : Colors.black,
                            foregroundColor:
                                _isFollowing ? Colors.black : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                  color: _isFollowing
                                      ? Colors.grey[300]!
                                      : Colors.black),
                            ),
                          ),
                          child: Text(
                              _isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  receiverId: widget.userId,
                                  receiverName: widget.userName,
                                  receiverAvatar: widget.userAvatar,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Nhắn tin',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const TabBar(
              indicatorColor: Colors.black,
              tabs: [Tab(text: 'Bài đăng'), Tab(text: 'Ảnh')],
            ),
            // --- DANH SÁCH BÀI ĐĂNG THẬT ---
            Expanded(
              child: TabBarView(
                children: [
                  _buildRealPosts(),
                  _buildRealMedia(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealPosts() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading)
          return const Center(
              child: CircularProgressIndicator(color: Colors.black));
        if (state is ProfileLoaded) {
          if (state.posts.isEmpty)
            return const Center(child: Text('Chưa có bài đăng nào.'));
          return ListView.separated(
            padding: const EdgeInsets.only(top: 16),
            itemCount: state.posts.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) => _postItem(state.posts[index]),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _postItem(PostEntity post) {
    String time = post.timestamp != null
        ? DateFormat('dd/MM').format(post.timestamp!)
        : '';
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(post.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          if (post.caption.isNotEmpty) Text(post.caption),
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(post.imageUrls.first, fit: BoxFit.cover),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildRealMedia() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoaded) {
          final images = state.posts.expand((p) => p.imageUrls).toList();
          if (images.isEmpty) return const Center(child: Text('Không có ảnh.'));
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
            itemCount: images.length,
            itemBuilder: (context, index) =>
                Image.network(images[index], fit: BoxFit.cover),
          );
        }
        return const SizedBox();
      },
    );
  }
}
