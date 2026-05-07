import 'package:checking_travel_app/data/datasources/auth_remote_data_source.dart';
import 'package:checking_travel_app/data/repositories/auth_repository_impl.dart';
import 'package:checking_travel_app/domain/usecases/sign_up_usecase.dart';
import 'package:checking_travel_app/feature/bloc/sign_up/sign_up_bloc.dart';
import 'package:checking_travel_app/feature/pages/main_layout.dart';
import 'package:checking_travel_app/feature/pages/sign_up.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/gestures.dart';

import '../bloc/sign_in/sign_in_bloc.dart';

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<SignInBloc, SignInState>(
        listener: (context, state) {
          if (state is SignInSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainLayout()),
            );
          } else if (state is SignInFailure) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Login Error"),
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
                  height: 450,
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
                          const Text("Đăng Nhập",
                              style: TextStyle(
                                  fontSize: 36, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 30),

                          /// EMAIL
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Text("EMAIL *")),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _email,
                            validator: (value) => value!.isEmpty
                                ? 'Vui lòng nhập email'
                                : null,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.email),
                              hintText: "Nhập email",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          /// PASSWORD
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Mật khẩu *")),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscurePassword,
                            validator: (value) => value!.isEmpty
                                ? 'Vui lòng nhập mật khẩu'
                                : null,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock),
                              hintText: "Nhập mật khẩu",
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
                          ),

                          /// FORGOT
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text("Quên mật khẩu?",
                                  style: TextStyle(color: Color(0xff6a62b7))),
                            ),
                          ),
                          const SizedBox(height: 20),

                          /// BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              // Gọi sự kiện gửi lên BLoC
                              onPressed: state is SignInLoading
                                  ? null
                                  : () {
                                      FocusScope.of(context).unfocus();
                                      if (_formKey.currentState!.validate()) {
                                        context.read<SignInBloc>().add(
                                            SignInSubmitted(_email.text.trim(),
                                                _password.text.trim()));
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff6a62b7),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              // Vẽ giao diện tùy theo state
                              child: state is SignInLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text("Đăng nhập",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// SIGN UP
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: "Bạn chưa có tài khoản? ",
                                  style: const TextStyle(color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: "Đăng ký",
                                      style: const TextStyle(
                                          color: Color(0xff6a62b7),
                                          fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          final authDataSource =
                                              AuthRemoteDataSource(
                                                  FirebaseAuth.instance);
                                          final authRepository =
                                              AuthRepositoryImpl(
                                                  authDataSource);
                                          final signUpUseCase =
                                              SignUpUseCase(authRepository);

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => BlocProvider(
                                                  create: (context) =>
                                                      SignUpBloc(
                                                          signUpUseCase:
                                                              signUpUseCase),
                                                  child: const SignupModel()),
                                            ),
                                          );
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
