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

import 'package:checking_travel_app/feature/pages/hotel_search_screen.dart';
import 'package:checking_travel_app/feature/pages/find_guide_screen.dart';

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
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey[200],
            backgroundImage: currentUser?.photoURL != null ? NetworkImage(currentUser!.photoURL!) : null,
            child: currentUser?.photoURL == null ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Xin chào, ${currentUser?.displayName ?? 'Bạn'} 👋', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.normal)),
            const Text('Hôm nay bạn muốn đi đâu?', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black, size: 28), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.black,
        onRefresh: () async {
          context.read<HomeBloc>().add(LoadPosts());
        },
        child: CustomScrollView(
          slivers: [
            // 1. THANH TÌM KIẾM
            SliverToBoxAdapter(child: _buildSearchBar()),

            // 2. CÁC DANH MỤC (Khách sạn, HDV...)
            SliverToBoxAdapter(child: _buildCategories(context)),

            // 3. KHÁCH SẠN NỔI BẬT
            SliverToBoxAdapter(child: _buildSectionTitle('Khách sạn nổi bật 🏨', 'Xem tất cả', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HotelSearchScreen()));
            })),
            SliverToBoxAdapter(child: _buildFeaturedHotels()),

            // 4. CỘNG ĐỒNG CHIA SẺ (Feed)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 10),
                child: Divider(thickness: 6, color: Colors.grey[100]),
              ),
            ),
            SliverToBoxAdapter(child: _buildSectionTitle('Cộng đồng du lịch 🌍', '', () {})),
            SliverToBoxAdapter(child: _buildCreatePostTrigger(context)),
            SliverToBoxAdapter(child: Divider(thickness: 1, color: Colors.grey[200], height: 1)),
            SliverToBoxAdapter(child: _buildFeed()),
          ],
        ),
      ),
    );
  }

  // =================================================================
  // CÁC WIDGET DÀNH CHO PHẦN DU LỊCH (TRAVEL)
  // =================================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        readOnly: true,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HotelSearchScreen())),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm khách sạn, địa điểm...',
          prefixIcon: const Icon(Icons.search, color: Colors.blue),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCategoryItem(Icons.hotel, 'Khách sạn', Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HotelSearchScreen()))),
          _buildCategoryItem(Icons.support_agent, 'Tìm HDV', Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FindGuideScreen()))),
          _buildCategoryItem(Icons.flight, 'Chuyến bay', Colors.red, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng sắp ra mắt!')));
          }),
          _buildCategoryItem(Icons.explore, 'Khám phá', Colors.green, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng sắp ra mắt!')));
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String actionText, VoidCallback onActionTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (actionText.isNotEmpty)
            GestureDetector(
              onTap: onActionTap,
              child: Text(actionText, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedHotels() {
    return SizedBox(
      height: 220,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('hotels').orderBy('rating', descending: true).limit(5).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final hotels = snapshot.data!.docs;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: hotels.length,
            itemBuilder: (context, index) {
              var data = hotels[index].data() as Map<String, dynamic>;

              // --- XỬ LÝ FORMAT GIÁ TIỀN Ở ĐÂY ---
              int rawPrice = (data['price'] ?? 0) is String
                  ? int.tryParse(data['price'].toString()) ?? 0
                  : (data['price'] ?? 0).toInt();
              String formattedPrice = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(rawPrice);

              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.network(
                          data['imageUrl'] ?? '',
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(height: 110, color: Colors.grey[300], child: const Icon(Icons.hotel))
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              Text(' ${data['rating'] ?? 5.0}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // IN GIÁ TIỀN ĐÃ FORMAT RA MÀN HÌNH
                          Text(formattedPrice, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // =================================================================
  // CÁC WIDGET DÀNH CHO PHẦN CỘNG ĐỒNG (FEED)
  // =================================================================

  Widget _buildCreatePostTrigger(BuildContext context) {
    return InkWell(
      onTap: () {
        final postDataSource = PostRemoteDataSource(FirebaseFirestore.instance, FirebaseAuth.instance);
        final postRepository = PostRepositoryImpl(postDataSource);
        final createPostUseCase = CreatePostUseCase(postRepository);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => CreatePostBloc(createPostUseCase: createPostUseCase),
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
              backgroundImage: currentUser?.photoURL != null ? NetworkImage(currentUser!.photoURL!) : null,
              child: currentUser?.photoURL == null ? const Icon(Icons.person, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                child: Text('Chia sẻ chuyến đi của bạn...', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
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
          return const Padding(padding: EdgeInsets.only(top: 50.0, bottom: 50.0), child: Center(child: CircularProgressIndicator(color: Colors.black)));
        } else if (state is HomeError) {
          return Padding(padding: const EdgeInsets.only(top: 50.0, bottom: 50.0), child: Center(child: Text('Lỗi: ${state.message}', style: const TextStyle(color: Colors.red))));
        } else if (state is HomeLoaded) {
          if (state.posts.isEmpty) {
            return const Padding(padding: EdgeInsets.only(top: 50.0, bottom: 50.0), child: Center(child: Text('Chưa có bài viết nào.', style: TextStyle(color: Colors.grey))));
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.posts.length,
            separatorBuilder: (context, index) => Divider(thickness: 1, color: Colors.grey[200]),
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

  Future<void> _handleLike() async {
    if (currentUser == null) return;

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      await FirebaseFirestore.instance.collection('posts').doc(widget.post.id).update({
        'likes': _isLiked
            ? FieldValue.arrayUnion([currentUser!.uid])
            : FieldValue.arrayRemove([currentUser!.uid])
      });

      if (_isLiked && currentUser!.uid != widget.post.userId) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.post.userId)
            .collection('notifications')
            .add({
          'type': 'like',
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
    final postDataSource = PostRemoteDataSource(FirebaseFirestore.instance, FirebaseAuth.instance);
    final postRepository = PostRepositoryImpl(postDataSource);
    final getUserPostsUseCase = GetUserPostsUseCase(postRepository);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => ProfileBloc(getUserPostsUseCase: getUserPostsUseCase),
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
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 12),
                if (currentUser != null)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
                    builder: (context, snapshot) {
                      bool isSaved = false;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        List savedPosts = (snapshot.data!.data() as Map<String, dynamic>)['savedPosts'] ?? [];
                        isSaved = savedPosts.contains(widget.post.id);
                      }

                      return ListTile(
                        leading: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.black),
                        title: Text(isSaved ? 'Bỏ lưu bài viết' : 'Lưu bài viết', style: const TextStyle(fontWeight: FontWeight.w600)),
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            if (isSaved) {
                              await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
                                'savedPosts': FieldValue.arrayRemove([widget.post.id])
                              });
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã bỏ lưu bài viết')));
                            } else {
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
                    Navigator.pop(context);
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
              backgroundImage: widget.post.userAvatar.isNotEmpty ? NetworkImage(widget.post.userAvatar) : null,
              child: widget.post.userAvatar.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
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
                      child: Text(widget.post.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    Row(
                      children: [
                        Text(timeString, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: _showPostOptions,
                          borderRadius: BorderRadius.circular(15),
                          child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.more_horiz, size: 20, color: Colors.black)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (widget.post.caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(widget.post.caption, style: const TextStyle(fontSize: 15, height: 1.3)),
                  ),
                if (widget.post.imageUrls.isNotEmpty)
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.post.imageUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(right: index == widget.post.imageUrls.length - 1 ? 0 : 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.post.imageUrls[index],
                              width: MediaQuery.of(context).size.width * 0.7,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) => progress == null ? child : Container(width: MediaQuery.of(context).size.width * 0.7, color: Colors.grey[100]),
                              errorBuilder: (context, error, stackTrace) => Container(width: MediaQuery.of(context).size.width * 0.7, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    InkWell(
                      onTap: _handleLike,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0, top: 4.0, bottom: 4.0),
                        child: Row(
                          children: [
                            Icon(_isLiked ? Icons.favorite : Icons.favorite_border, size: 22, color: _isLiked ? Colors.red : Colors.black),
                            if (_likeCount > 0) ...[
                              const SizedBox(width: 4),
                              Text('$_likeCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ]
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        final commentRepo = CommentRepositoryImpl(FirebaseFirestore.instance, FirebaseAuth.instance);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => BlocProvider(
                            create: (context) => CommentBloc(repository: commentRepo),
                            child: CommentSheet(postId: widget.post.id),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.chat_bubble_outline, size: 22, color: Colors.black)),
                    ),
                    const SizedBox(width: 16),
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
                      child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.send_outlined, size: 22, color: Colors.black)),
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