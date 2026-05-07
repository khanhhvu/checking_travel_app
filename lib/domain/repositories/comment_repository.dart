import 'package:checking_travel_app/domain/entities/comment_entity.dart';

abstract class CommentRepository {
  Stream<List<CommentEntity>> getCommentsStream(String postId);

  Future<void> addComment(String postId, String content);
}
