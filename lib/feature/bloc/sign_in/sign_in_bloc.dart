import 'package:checking_travel_app/domain/usecases/sign_in_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';


// --- EVENTS (Sự kiện từ UI gửi lên) ---
abstract class SignInEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class SignInSubmitted extends SignInEvent {
  final String email;
  final String password;

  SignInSubmitted(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

// --- STATES (Trạng thái BLoC trả về UI) ---
abstract class SignInState extends Equatable {
  @override
  List<Object> get props => [];
}

class SignInInitial extends SignInState {}
class SignInLoading extends SignInState {}
class SignInSuccess extends SignInState {}
class SignInFailure extends SignInState {
  final String errorMessage;
  SignInFailure(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}


class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final SignInUseCase signInUseCase;

  SignInBloc({required this.signInUseCase}) : super(SignInInitial()) {
    on<SignInSubmitted>((event, emit) async {
      emit(SignInLoading()); // Báo UI hiện vòng quay
      try {
        await signInUseCase.execute(event.email, event.password);
        emit(SignInSuccess()); // Báo UI chuyển trang
      } catch (e) {
        emit(SignInFailure(e.toString().replaceAll('Exception: ', ''))); // Báo UI hiện lỗi
      }
    });
  }
}