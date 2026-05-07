import 'package:checking_travel_app/data/datasources/auth_remote_data_source.dart';
import 'package:checking_travel_app/data/repositories/auth_repository_impl.dart';
import 'package:checking_travel_app/domain/usecases/sign_in_usecase.dart';
import 'package:checking_travel_app/feature/bloc/sign_in/sign_in_bloc.dart';
import 'package:checking_travel_app/feature/bloc/sign_up/sign_up_bloc.dart';
import 'package:checking_travel_app/feature/pages/main_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/gestures.dart';

import 'sign_in.dart';

class SignupModel extends StatefulWidget {
  const SignupModel({super.key});

  @override
  State<SignupModel> createState() => _SignupModelState();
}

class _SignupModelState extends State<SignupModel> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Bọc toàn bộ body bằng BlocConsumer để lắng nghe state
      body: BlocConsumer<SignUpBloc, SignUpState>(
        listener: (context, state) {
          if (state is SignUpSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainLayout()),
            );
          } else if (state is SignUpFailure) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Sign Up Error"),
                content: Text(state.errorMessage),
                actions: [
                  TextButton(
                    child: const Text("OK"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                child: Image.asset(
                  'assets/images/image1.png',
                  height: 360,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          const Text("Đăng Ký",
                              style: TextStyle(
                                  fontSize: 36, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          const SizedBox(height: 30),

                          /// EMAIL
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Text("EMAIL *")),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.email),
                              hintText: "Nhập email",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Vui lòng nhập email';
                              if (!value.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          /// PASSWORD
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Mật khẩu *")),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock),
                              hintText: "Nhập password",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Vui lòng nhập mật khẩu';
                              if (value.length < 6)
                                return 'Mật khẩu không được ngắn hơn 6 kí tự';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          /// CONFIRM PASSWORD
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Xác nhận mật khẩu *")),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline),
                              hintText: "Nhập lại mật khẩu",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text)
                                return 'Mật khẩu không khớp';
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),

                          /// BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              // Logic BLoC ở đây: Nếu đang load thì cấm bấm, nếu không thì gửi Event
                              onPressed: state is SignUpLoading
                                  ? null
                                  : () {
                                      FocusScope.of(context).unfocus();
                                      if (_formKey.currentState!.validate()) {
                                        context.read<SignUpBloc>().add(
                                            SignUpSubmitted(
                                                _emailController.text.trim(),
                                                _passwordController.text
                                                    .trim()));
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff6a62b7),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              child: state is SignUpLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text("Đăng ký",
                                      style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          /// SIGN IN
                          RichText(
                            text: TextSpan(
                              text: "Bạn đã có tài khoản? ",
                              style: const TextStyle(color: Colors.black),
                              children: [
                                TextSpan(
                                  text: "Đăng nhập", // Sửa lại chữ cho đúng
                                  style: const TextStyle(
                                      color: Color(0xff6a62b7),
                                      fontWeight: FontWeight.bold),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      // 1. Khởi tạo UseCase ĐĂNG NHẬP
                                      final authDataSource = AuthRemoteDataSource(FirebaseAuth.instance);
                                      final authRepository = AuthRepositoryImpl(authDataSource);
                                      final signInUseCase = SignInUseCase(authRepository); // Sửa thành SignInUseCase

                                      // 2. Chuyển sang màn ĐĂNG NHẬP cùng SignInBloc
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BlocProvider(
                                            create: (context) => SignInBloc(signInUseCase: signInUseCase), // Dùng SignInBloc
                                            child: SignIn(), // Thay bằng tên file giao diện Đăng Nhập của bạn
                                          ),
                                        ),
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
