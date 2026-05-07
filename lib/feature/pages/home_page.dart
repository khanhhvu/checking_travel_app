import 'package:checking_travel_app/data/datasources/comment_remote_data_source.dart';
import 'package:checking_travel_app/data/datasources/post_remote_data_source.dart';
import 'package:checking_travel_app/data/repositories/post_repository_impl.dart';
import 'package:checking_travel_app/domain/entities/post_entity.dart';
import 'package:checking_travel_app/domain/usecases/create_post_usecase.dart';
import 'package:checking_travel_app/domain/usecases/get_user_posts_usecase.dart';
import 'package:checking_travel_app/feature/bloc/comment/comment_bloc.dart';
import 'package:checking_travel_app/feature/bloc/create_post/create_post_bloc.dart';
import 'package:checking_travel_app/feature/bloc/home/home_bloc.dart';
import 'package:checking_travel_app/feature/bloc/profile/profile_bloc.dart';
import 'package:checking_travel_app/feature/pages/chat_detail.dart';
import 'package:checking_travel_app/feature/pages/create_post.dart';
import 'package:checking_travel_app/feature/pages/other_user_profile.dart';
import 'package:checking_travel_app/feature/widgets/comment_sheet.dart';
import 'package:checking_travel_app/feature/widgets/share_post_sheet.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(LoadPosts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black, size: 28),
          onPressed: () {},
        ),
        title: const Text(
          'Checking Travel',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Playwrite',
            fontSize: 25,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.search, color: Colors.black, size: 28),
              onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.black,
        onRefresh: () async {
          context.read<HomeBloc>().add(LoadPosts());
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildCreatePostTrigger(context)),
            SliverToBoxAdapter(
                child:
                    Divider(thickness: 1, color: Colors.grey[200], height: 1)),
            SliverToBoxAdapter(child: _buildFeed()),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePostTrigger(BuildContext context) {
    return InkWell(
      onTap: () {
        final postDataSource = PostRemoteDataSource(
            FirebaseFirestore.instance, FirebaseAuth.instance);
        final postRepository = PostRepositoryImpl(postDataSource);
        final createPostUseCase = CreatePostUseCase(postRepository);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) =>
                  CreatePostBloc(createPostUseCase: createPostUseCase),
              child: const CreatePost(),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage: currentUser?.photoURL != null
                  ? NetworkImage(currentUser!.photoURL!)
                  : null,
              child: currentUser?.photoURL == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser?.displayName ?? 'Khách du lịch',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text('Có gì mới?',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Padding(
              padding: EdgeInsets.only(top: 50.0),
              child: Center(
                  child: CircularProgressIndicator(color: Colors.black)));
        } else if (state is HomeError) {
          return Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: Center(
                  child: Text('Lỗi: ${state.message}',
                      style: const TextStyle(color: Colors.red))));
        } else if (state is HomeLoaded) {
          if (state.posts.isEmpty) {
            return const Padding(
                padding: EdgeInsets.only(top: 50.0),
                child: Center(
                    child: Text('Chưa có chuyến đi nào được chia sẻ.',
                        style: TextStyle(color: Colors.grey))));
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.posts.length,
            separatorBuilder: (context, index) =>
                Divider(thickness: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              return PostItemWidget(post: state.posts[index]);
            },
          );
        }
        return const SizedBox();
      },
    );
  }
}

class PostItemWidget extends StatefulWidget {
  final PostEntity post;

  const PostItemWidget({Key? key, required this.post}) : super(key: key);

  @override
  State<PostItemWidget> createState() => _PostItemWidgetState();
}

class _PostItemWidgetState extends State<PostItemWidget> {
  bool _isLiked = false;
  int _likeCount = 0;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    try {
      if (currentUser != null) {
        _isLiked = widget.post.likes.contains(currentUser!.uid);
      }
      _likeCount = widget.post.likes.length;
    } catch (e) {
      _isLiked = false;
      _likeCount = 0;
    }
  }

  // --- HÀM XỬ LÝ THÍCH BÀI VIẾT ---
  Future<void> _handleLike() async {
    if (currentUser == null) return;

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      // 1. Lưu trạng thái thả tim vào bài viết
      await FirebaseFirestore.instance.collection('posts').doc(widget.post.id).update({
        'likes': _isLiked
            ? FieldValue.arrayUnion([currentUser!.uid])
            : FieldValue.arrayRemove([currentUser!.uid])
      });

      // 2. THÔNG BÁO (Nếu họ thả tim và họ không phải chủ bài viết)
      if (_isLiked && currentUser!.uid != widget.post.userId) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.post.userId) // Hòm thư của chủ bài viết
            .collection('notifications')
            .add({
          'type': 'like', // Loại thông báo: Thích
          'senderId': currentUser!.uid,
          'senderName': currentUser!.displayName ?? 'Người dùng',
          'senderAvatar': currentUser!.photoURL ?? '',
          'postId': widget.post.id,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    } catch (e) {
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
    }
  }

  void _navigateToUserProfile() {
    final postDataSource =
        PostRemoteDataSource(FirebaseFirestore.instance, FirebaseAuth.instance);
    final postRepository = PostRepositoryImpl(postDataSource);
    final getUserPostsUseCase = GetUserPostsUseCase(postRepository);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) =>
              ProfileBloc(getUserPostsUseCase: getUserPostsUseCase),
          child: OtherUserProfile(
            userId: widget.post.userId,
            userName: widget.post.userName,
            userAvatar: widget.post.userAvatar,
          ),
        ),
      ),
    );
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                    width: 40, height: 5,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))
                ),
                const SizedBox(height: 12),

                // --- NÚT LƯU BÀI VIẾT (TỰ ĐỘNG CẬP NHẬT TRẠNG THÁI) ---
                if (currentUser != null)
                  StreamBuilder<DocumentSnapshot>(
                    // Lắng nghe dữ liệu của chính mình để biết mảng savedPosts đang có những bài nào
                    stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
                    builder: (context, snapshot) {
                      bool isSaved = false;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        List savedPosts = (snapshot.data!.data() as Map<String, dynamic>)['savedPosts'] ?? [];
                        isSaved = savedPosts.contains(widget.post.id); // Kiểm tra bài viết hiện tại đã lưu chưa
                      }

                      return ListTile(
                        leading: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? Colors.black : Colors.black,
                        ),
                        title: Text(
                          isSaved ? 'Bỏ lưu bài viết' : 'Lưu bài viết',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () async {
                          Navigator.pop(context); // Đóng bảng tùy chọn trước cho mượt

                          try {
                            if (isSaved) {
                              // Nếu đã lưu -> Xóa khỏi mảng
                              await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
                                'savedPosts': FieldValue.arrayRemove([widget.post.id])
                              });
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã bỏ lưu bài viết')));
                            } else {
                              // Nếu chưa lưu -> Thêm vào mảng
                              await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
                                'savedPosts': FieldValue.arrayUnion([widget.post.id]),
                              });
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu bài viết vào trang cá nhân!')));
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                          }
                        },
                      );
                    },
                  ),

                ListTile(
                  leading: const Icon(Icons.share_outlined, color: Colors.black),
                  title: const Text('Chia sẻ bài viết', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context); // Đóng popup 3 chấm trước

                    // Mở popup chia sẻ lên
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => SharePostSheet(postId: widget.post.id),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String timeString = '';
    if (widget.post.timestamp != null) {
      timeString = DateFormat('dd/MM HH:mm').format(widget.post.timestamp!);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _navigateToUserProfile,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.post.userAvatar.isNotEmpty
                  ? NetworkImage(widget.post.userAvatar)
                  : null,
              child: widget.post.userAvatar.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _navigateToUserProfile,
                      child: Text(widget.post.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    Row(
                      children: [
                        Text(timeString,
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 13)),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: _showPostOptions,
                          borderRadius: BorderRadius.circular(15),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.more_horiz,
                                size: 20, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (widget.post.caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(widget.post.caption,
                        style: const TextStyle(fontSize: 15, height: 1.3)),
                  ),
                if (widget.post.imageUrls.isNotEmpty)
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.post.imageUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                              right: index == widget.post.imageUrls.length - 1
                                  ? 0
                                  : 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.post.imageUrls[index],
                              width: MediaQuery.of(context).size.width * 0.7,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) =>
                                  progress == null
                                      ? child
                                      : Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.7,
                                          color: Colors.grey[100]),
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.7,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image,
                                          color: Colors.grey)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),

                // --- THANH TƯƠNG TÁC (Thích, Comment, Share) ---
                Row(
                  children: [
                    InkWell(
                      onTap: _handleLike,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            right: 8.0, top: 4.0, bottom: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 22,
                              color: _isLiked ? Colors.red : Colors.black,
                            ),
                            if (_likeCount > 0) ...[
                              const SizedBox(width: 4),
                              Text('$_likeCount',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ]
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // NÚT BÌNH LUẬN
                    InkWell(
                      onTap: () {
                        final commentRepo = CommentRepositoryImpl(
                            FirebaseFirestore.instance, FirebaseAuth.instance);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => BlocProvider(
                            create: (context) =>
                                CommentBloc(repository: commentRepo),
                            child: CommentSheet(postId: widget.post.id),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.chat_bubble_outline,
                            size: 22, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // NÚT CHIA SẺ / NHẮN TIN
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              receiverId: widget.post.userId,
                              receiverName: widget.post.userName,
                              receiverAvatar: widget.post.userAvatar,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.send_outlined,
                            size: 22, color: Colors.black),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
