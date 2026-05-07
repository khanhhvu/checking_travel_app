import 'package:checking_travel_app/domain/usecases/create_post_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// --- EVENTS ---
abstract class CreatePostEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class PostSubmitted extends CreatePostEvent {
  final String caption;
  final List<String> imagePaths;

  PostSubmitted(this.caption, this.imagePaths);

  @override
  List<Object> get props => [caption, imagePaths];
}

abstract class CreatePostState extends Equatable {
  @override
  List<Object> get props => [];
}

class CreatePostInitial extends CreatePostState {}

class CreatePostLoading extends CreatePostState {}

class CreatePostSuccess extends CreatePostState {}

class CreatePostFailure extends CreatePostState {
  final String errorMessage;

  CreatePostFailure(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

// BLOC
class CreatePostBloc extends Bloc<CreatePostEvent, CreatePostState> {
  final CreatePostUseCase createPostUseCase;

  CreatePostBloc({required this.createPostUseCase})
      : super(CreatePostInitial()) {
    on<PostSubmitted>((event, emit) async {
      emit(CreatePostLoading()); // Bật vòng quay
      try {
        await createPostUseCase.execute(event.caption, event.imagePaths);
        emit(CreatePostSuccess());
      } catch (e) {
        emit(CreatePostFailure(e.toString())); // Báo lỗi
      }
    });
  }
}
