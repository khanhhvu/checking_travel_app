import 'package:checking_travel_app/domain/entities/post_entity.dart';
import 'package:checking_travel_app/domain/usecases/get_posts_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';


// --- EVENTS ---
abstract class HomeEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadPosts extends HomeEvent {}

// --- STATES ---
abstract class HomeState extends Equatable {
  @override
  List<Object> get props => [];
}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<PostEntity> posts;
  HomeLoaded(this.posts);

  @override
  List<Object> get props => [posts];
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);

  @override
  List<Object> get props => [message];
}

// --- BLOC ---
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetPostsUseCase getPostsUseCase;

  HomeBloc({required this.getPostsUseCase}) : super(HomeLoading()) {
    on<LoadPosts>((event, emit) async {
      emit(HomeLoading());
      // Sử dụng emit.forEach để lắng nghe stream liên tục từ Firebase
      await emit.forEach<List<PostEntity>>(
        getPostsUseCase.execute(),
        onData: (posts) => HomeLoaded(posts),
        onError: (error, stackTrace) => HomeError(error.toString()),
      );
    });
  }
}