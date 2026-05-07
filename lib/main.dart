import 'package:checking_travel_app/data/datasources/auth_remote_data_source.dart';
import 'package:checking_travel_app/data/repositories/auth_repository_impl.dart';
import 'package:checking_travel_app/domain/usecases/sign_in_usecase.dart';
import 'package:checking_travel_app/feature/bloc/sign_in/sign_in_bloc.dart';
import 'package:checking_travel_app/feature/pages/sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widgets is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (context) {
          // Khởi tạo các lớp từ dưới lên trên
          final dataSource = AuthRemoteDataSource(FirebaseAuth.instance);
          final repository = AuthRepositoryImpl(dataSource);
          final useCase = SignInUseCase(repository);
          return SignInBloc(signInUseCase: useCase);
        },
        child: SignIn(),
      ),
    );
  }
}
