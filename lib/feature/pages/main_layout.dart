import 'package:checking_travel_app/data/datasources/post_remote_data_source.dart';
import 'package:checking_travel_app/data/repositories/post_repository_impl.dart';
import 'package:checking_travel_app/domain/usecases/create_post_usecase.dart';
import 'package:checking_travel_app/domain/usecases/get_posts_usecase.dart';
import 'package:checking_travel_app/domain/usecases/get_user_posts_usecase.dart';
import 'package:checking_travel_app/feature/bloc/create_post/create_post_bloc.dart';
import 'package:checking_travel_app/feature/bloc/home/home_bloc.dart';
import 'package:checking_travel_app/feature/bloc/profile/profile_bloc.dart';
import 'package:checking_travel_app/feature/pages/chat_message.dart';
import 'package:checking_travel_app/feature/pages/create_post.dart';
import 'package:checking_travel_app/feature/pages/favorite.dart';
import 'package:checking_travel_app/feature/pages/home_page.dart';
import 'package:checking_travel_app/feature/pages/profile.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    final postDataSource =
        PostRemoteDataSource(FirebaseFirestore.instance, FirebaseAuth.instance);
    final postRepository = PostRepositoryImpl(postDataSource);
    final getPostsUseCase = GetPostsUseCase(postRepository);
    final getUserPostsUseCase = GetUserPostsUseCase(postRepository);
    _pages = [
      BlocProvider(
        create: (context) => HomeBloc(getPostsUseCase: getPostsUseCase),
        child: const HomePage(),
      ),
      const ChatMessage(),
      const SizedBox(),
      const Favorite(),
      BlocProvider(
        create: (context) => ProfileBloc(getUserPostsUseCase: getUserPostsUseCase),
        child: const Profile(),
      ),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      final postDataSource = PostRemoteDataSource(
          FirebaseFirestore.instance, FirebaseAuth.instance);
      final postRepository = PostRepositoryImpl(postDataSource);
      final createPostUseCase = CreatePostUseCase(postRepository);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) =>
                CreatePostBloc(createPostUseCase: createPostUseCase),
            child: const CreatePost(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  final List<IconData> _icons = [
    Icons.home_outlined,
    Icons.send_outlined,
    Icons.add_box_outlined,
    Icons.favorite_border,
    Icons.person_outline,
  ];

  final List<IconData> _activeIcons = [
    Icons.home,
    Icons.send,
    Icons.add_box,
    Icons.favorite,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: List.generate(_icons.length, (index) {
          return BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == index ? _activeIcons[index] : _icons[index],
              size: index == 2 ? 50 : 28,
            ),
            label: '',
          );
        }),
      ),
    );
  }
}
