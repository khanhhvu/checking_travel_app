import 'package:checking_travel_app/data/datasources/auth_remote_data_source.dart';
import 'package:checking_travel_app/data/repositories/auth_repository_impl.dart';
import 'package:checking_travel_app/domain/usecases/sign_in_usecase.dart';
import 'package:checking_travel_app/feature/bloc/profile/profile_bloc.dart';
import 'package:checking_travel_app/feature/bloc/sign_in/sign_in_bloc.dart';
import 'package:checking_travel_app/feature/pages/post_detail.dart';
import 'package:checking_travel_app/feature/pages/settings.dart';
import 'package:checking_travel_app/feature/pages/sign_in.dart';
import 'package:checking_travel_app/feature/widgets/edit_profile_sheet.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      context.read<ProfileBloc>().add(LoadProfilePosts(currentUser!.uid));
    }
  }

  Future<void> _signOut(BuildContext context) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đăng xuất',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => SignIn()),
            (route) => false);
      }
    }
  }

  // --- HÀM XỬ LÝ ĐĂNG XUẤT CÓ HỘP THOẠI XÁC NHẬN ---
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Đăng xuất',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content:
              const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await FirebaseAuth.instance.signOut();

                final authDataSource =
                    AuthRemoteDataSource(FirebaseAuth.instance);
                final authRepository = AuthRepositoryImpl(authDataSource);
                final signInUseCase = SignInUseCase(authRepository);

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) =>
                            SignInBloc(signInUseCase: signInUseCase),
                        child: SignIn(),
                      ),
                    ),
                    (route) => false,
                  );
                }
              },
              child: const Text('Đăng xuất',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
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
          leading: const Icon(Icons.language, color: Colors.black),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: _handleLogout,
            ),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser?.displayName ?? 'Khách du lịch',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentUser?.email ?? 'Chưa cập nhật email',
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black87),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: currentUser?.photoURL != null
                            ? NetworkImage(currentUser!.photoURL!)
                            : null,
                        child: currentUser?.photoURL == null
                            ? const Icon(Icons.person,
                                size: 40, color: Colors.grey)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // --- HIỂN THỊ TIỂU SỬ BẰNG STREAM BUIDLER ---
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      String bio =
                          'Thêm tiểu sử để mọi người hiểu hơn về bạn nhé...';
                      int followerCount = 0;
                      int followingCount = 0;

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        if (data != null) {
                          // Lấy tiểu sử
                          if (data['bio'] != null &&
                              data['bio'].toString().isNotEmpty) {
                            bio = data['bio'];
                          }
                          // Lấy số người theo dõi (độ dài mảng)
                          if (data['followers'] != null) {
                            followerCount = (data['followers'] as List).length;
                          }
                          // Lấy số người đang theo dõi (độ dài mảng)
                          if (data['following'] != null) {
                            followingCount = (data['following'] as List).length;
                          }
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // In Tiểu sử
                          Text(bio, style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 12),
                          // In số người theo dõi thật
                          Row(
                            children: [
                              Text('$followerCount ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Text('người theo dõi',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 14)),
                              const SizedBox(width: 16),
                              Text('$followingCount ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Text('đang theo dõi',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 14)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            if (currentUser != null) {
                              final result = await showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    EditProfileSheet(currentUser: currentUser!),
                              );
                              if (result == true) {
                                await currentUser?.reload();
                                setState(() {
                                  currentUser =
                                      FirebaseAuth.instance.currentUser;
                                });
                                // Mẹo nhỏ: Load lại cả bài viết trên trang Profile cho chắc ăn
                                context
                                    .read<ProfileBloc>()
                                    .add(LoadProfilePosts(currentUser!.uid));
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: const Text('Chỉnh sửa',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: const Text('Chia sẻ',
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
              indicatorWeight: 1.5,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              tabs: [Tab(text: 'Bài viết'), Tab(text: 'Đã lưu')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildProfilePosts(),
                  _buildSavedPosts(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePosts() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading)
          return const Center(
              child: CircularProgressIndicator(color: Colors.black));
        if (state is ProfileError)
          return Center(
              child: Text('Lỗi: ${state.message}',
                  style: const TextStyle(color: Colors.red)));

        if (state is ProfileLoaded) {
          final postsWithImages =
              state.posts.where((post) => post.imageUrls.isNotEmpty).toList();

          if (postsWithImages.isEmpty) {
            return const Center(
                child: Text('Chưa có ảnh nào được đăng.',
                    style: TextStyle(color: Colors.grey)));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
            itemCount: postsWithImages.length,
            itemBuilder: (context, index) {
              final post = postsWithImages[index]; // Lấy thông tin bài viết

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(postId: post.id),
                    ),
                  );
                },
                child: Image.network(
                  post.imageUrls.first,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(color: Colors.grey[200]);
                  },
                ),
              );
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildSavedPosts() {
    if (currentUser == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting)
          return const Center(
              child: CircularProgressIndicator(color: Colors.black));

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Center(
              child: Text('Chưa có chuyến đi nào được lưu.',
                  style: TextStyle(color: Colors.grey)));
        }

        List savedPostIds =
            (userSnapshot.data!.data() as Map<String, dynamic>)['savedPosts'] ??
                [];
        if (savedPostIds.isEmpty) {
          return const Center(
              child: Text('Chưa có chuyến đi nào được lưu.',
                  style: TextStyle(color: Colors.grey)));
        }

        List<dynamic> limitedIds = savedPostIds.length > 10
            ? savedPostIds.sublist(savedPostIds.length - 10)
            : savedPostIds;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where(FieldPath.documentId, whereIn: limitedIds)
              .snapshots(),
          builder: (context, postSnapshot) {
            if (postSnapshot.connectionState == ConnectionState.waiting)
              return const Center(
                  child: CircularProgressIndicator(color: Colors.black));

            if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text('Bài viết đã bị xóa.',
                      style: TextStyle(color: Colors.grey)));
            }

            final posts = postSnapshot.data!.docs;

            return GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final String postId = posts[index].id;
                var postData = posts[index].data() as Map<String, dynamic>;
                List images = postData['imageUrls'] ?? [];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(postId: postId),
                      ),
                    );
                  },
                  child: images.isNotEmpty
                      ? Image.network(images.first, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey)),
                );
              },
            );
          },
        );
      },
    );
  }
}
