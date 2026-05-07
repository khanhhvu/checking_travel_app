import 'package:checking_travel_app/domain/entities/comment_entity.dart';
import 'package:checking_travel_app/domain/repositories/comment_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';


// --- EVENTS ---
abstract class CommentEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadComments extends CommentEvent {
  final String postId;
  LoadComments(this.postId);
  @override
  List<Object> get props => [postId];
}

class SubmitComment extends CommentEvent {
  final String postId;
  final String content;
  SubmitComment(this.postId, this.content);
  @override
  List<Object> get props => [postId, content];
}

// --- STATES ---
abstract class CommentState extends Equatable {
  @override
  List<Object> get props => [];
}

class CommentLoading extends CommentState {}
class CommentLoaded extends CommentState {
  final List<CommentEntity> comments;
  CommentLoaded(this.comments);
  @override
  List<Object> get props => [comments];
}
class CommentError extends CommentState {
  final String message;
  CommentError(this.message);
  @override
  List<Object> get props => [message];
}

// --- BLOC ---
class CommentBloc extends Bloc<CommentEvent, CommentState> {
  final CommentRepository repository;

  CommentBloc({required this.repository}) : super(CommentLoading()) {
    on<LoadComments>((event, emit) async {
      emit(CommentLoading());
      await emit.forEach<List<CommentEntity>>(
        repository.getCommentsStream(event.postId),
        onData: (comments) => CommentLoaded(comments),
        onError: (error, _) => CommentError(error.toString()),
      );
    });

    on<SubmitComment>((event, emit) async {
      try {
        await repository.addComment(event.postId, event.content);
        // Không cần emit State mới vì Stream ở LoadComments sẽ tự động đẩy data mới về
      } catch (e) {
        emit(CommentError(e.toString()));
      }
    });
  }
}