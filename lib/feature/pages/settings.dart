import 'package:checking_travel_app/data/datasources/auth_remote_data_source.dart';
import 'package:checking_travel_app/data/repositories/auth_repository_impl.dart';
import 'package:checking_travel_app/domain/usecases/sign_in_usecase.dart';
import 'package:checking_travel_app/feature/bloc/sign_in/sign_in_bloc.dart';
import 'package:checking_travel_app/feature/pages/find_guide_screen.dart';
import 'package:checking_travel_app/feature/pages/guide_dashboard_screen.dart';
import 'package:checking_travel_app/feature/pages/guide_registration_screen.dart';
import 'package:checking_travel_app/feature/pages/hotel_search_screen.dart';
import 'package:checking_travel_app/feature/pages/my_tours_screen.dart';
import 'package:checking_travel_app/feature/pages/about_screen.dart';
import 'package:checking_travel_app/feature/pages/my_bookings_screen.dart';
import 'package:checking_travel_app/feature/pages/sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _handleLogout(BuildContext context) {
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
                Navigator.pop(dialogContext); // Đóng Dialog

                await FirebaseAuth.instance.signOut();

                // Khởi tạo BLoC chống lỗi màn hình đỏ
                final authDataSource =
                    AuthRemoteDataSource(FirebaseAuth.instance);
                final authRepository = AuthRepositoryImpl(authDataSource);
                final signInUseCase = SignInUseCase(authRepository);

                if (context.mounted) {
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Cài đặt',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          _buildListTile(context, Icons.person_outline, 'Tài khoản', () {
            _showComingSoon(context);
          }),
          const Divider(height: 1, indent: 60),
          const SizedBox(height: 10),
          _buildListTile(context, Icons.hotel_outlined, 'Tìm khách sạn', () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const HotelSearchScreen()));
          }),
          _buildListTile(context, Icons.hotel_outlined, 'Khách sạn đã đặt', () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MyBookingsScreen()));
          }),
          _buildListTile(
              context, Icons.support_agent_outlined, 'Tìm hướng dẫn viên', () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FindGuideScreen()));
          }),
          _buildListTile(context, Icons.luggage_outlined, 'Lịch sử thuê HDV', () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyToursScreen()));
          }),
          _buildListTile(context, Icons.badge_outlined, 'Kênh Hướng dẫn viên',
              () async {
            final user = FirebaseAuth.instance.currentUser;

            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng đăng nhập!')));
              return;
            }

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                  child: CircularProgressIndicator(color: Colors.blue)),
            );

            try {
              final guideDoc = await FirebaseFirestore.instance
                  .collection('guides')
                  .doc(user.uid)
                  .get();

              if (context.mounted) Navigator.pop(context);

              if (guideDoc.exists && guideDoc.data()?['status'] == 'Approved') {
                // ĐÃ LÀ HDV -> Chuyển sang Dashboard
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GuideDashboardScreen()),
                  );
                }
              } else {
                // CHƯA LÀ HDV -> Chuyển sang màn Đăng ký
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GuideRegistrationScreen()),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi kiểm tra dữ liệu: $e')));
            }
          }),
          const Divider(height: 30, thickness: 8, color: Color(0xFFF5F5F5)),
          _buildListTile(context, Icons.help_outline, 'Trợ giúp', () {
            _showComingSoon(context);
          }),
          _buildListTile(context, Icons.info_outline, 'Giới thiệu', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            );
          }),
          const SizedBox(height: 20),
          const Divider(height: 1),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            leading: const Icon(Icons.logout, color: Colors.red, size: 28),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  // Widget dùng chung để vẽ các dòng menu cho đẹp và đều nhau
  Widget _buildListTile(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: Colors.black87, size: 28),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Thông báo tạm thời cho các chức năng chưa làm
  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng đang được phát triển!')),
    );
  }
}
