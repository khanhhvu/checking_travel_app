import 'package:checking_travel_app/domain/usecases/sign_up_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// --- EVENTS ---
abstract class SignUpEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class SignUpSubmitted extends SignUpEvent {
  final String email;
  final String password;

  SignUpSubmitted(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

// --- STATES ---
abstract class SignUpState extends Equatable {
  @override
  List<Object> get props => [];
}

class SignUpInitial extends SignUpState {}

class SignUpLoading extends SignUpState {}

class SignUpSuccess extends SignUpState {}

class SignUpFailure extends SignUpState {
  final String errorMessage;

  SignUpFailure(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

// --- BLOC ---
class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  final SignUpUseCase signUpUseCase;

  SignUpBloc({required this.signUpUseCase}) : super(SignUpInitial()) {
    on<SignUpSubmitted>((event, emit) async {
      emit(SignUpLoading());
      try {
        await signUpUseCase.execute(event.email, event.password);
        emit(SignUpSuccess());
      } catch (e) {
        emit(SignUpFailure(e.toString().replaceAll('Exception: ', '')));
      }
    });
  }
}
