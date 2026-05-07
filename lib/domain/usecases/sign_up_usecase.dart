import 'package:checking_travel_app/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<void> execute(String email, String password) {
    return repository.signUp(email, password);
  }
}
