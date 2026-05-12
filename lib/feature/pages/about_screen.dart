
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Giới thiệu',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.jpg',
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      height: 120,
                      width: 120,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: Colors.grey)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Checking Travel App',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 5),
            Text(
              'Phiên bản 1.0.0 (Beta)',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),

            const SizedBox(height: 40),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: const Column(
                children: [
                  Text(
                    'Giới thiệu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Checking Travel ra đời với sứ mệnh mang đến một nền tảng du lịch "All-in-one" (Tất cả trong một) thông minh. Ứng dụng không chỉ giúp du khách dễ dàng tìm kiếm phòng khách sạn với chi phí tối ưu, mà còn tiên phong trong việc kết nối trực tiếp khách du lịch với mạng lưới Hướng dẫn viên địa phương (Mô hình C2C) uy tín.\n\nĐược phát triển với tâm huyết và ứng dụng các công nghệ hiện đại, Checking Travel tự hào là một sản phẩm công nghệ do sinh viên Đại học Giao thông Vận tải (UTC) xây dựng.\n\nTôi hy vọng ứng dụng sẽ là người bạn đồng hành tin cậy, giúp mỗi chuyến đi của bạn trở nên an toàn, trọn vẹn và mang đậm dấu ấn cá nhân!',
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                        fontSize: 14, height: 1.6, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            Text(
              '© 2026 Đồ án Tốt Nghiệp',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 5),
            Text(
              'Phát triển bởi Sinh viên ĐH GTVT',
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
