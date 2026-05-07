import 'package:checking_travel_app/data/datasources/auth_remote_data_source.dart';
import 'package:checking_travel_app/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> signIn(String email, String password) async {
    await remoteDataSource.signInWithEmail(email, password);
  }

  @override
  Future<void> signUp(String email, String password) async {
    await remoteDataSource.signUpWithEmail(email, password);
  }
}
