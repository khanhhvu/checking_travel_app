import 'package:checking_travel_app/domain/entities/post_entity.dart';
import 'package:checking_travel_app/domain/usecases/get_user_posts_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// --- EVENTS ---
abstract class ProfileEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadProfilePosts extends ProfileEvent {
  final String userId;

  LoadProfilePosts(this.userId);

  @override
  List<Object> get props => [userId];
}

// --- STATES ---
abstract class ProfileState extends Equatable {
  @override
  List<Object> get props => [];
}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final List<PostEntity> posts;

  ProfileLoaded(this.posts);

  @override
  List<Object> get props => [posts];
}

class ProfileError extends ProfileState {
  final String message;

  ProfileError(this.message);

  @override
  List<Object> get props => [message];
}

// --- BLOC ---
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetUserPostsUseCase getUserPostsUseCase;

  ProfileBloc({required this.getUserPostsUseCase}) : super(ProfileLoading()) {
    on<LoadProfilePosts>((event, emit) async {
      emit(ProfileLoading());
      await emit.forEach<List<PostEntity>>(
        getUserPostsUseCase.execute(event.userId),
        onData: (posts) => ProfileLoaded(posts),
        onError: (error, stackTrace) => ProfileError(error.toString()),
      );
    });
  }
}
