import 'package:checking_travel_app/domain/entities/post_entity.dart';

abstract class PostRepository {
  Stream<List<PostEntity>> getPostsStream();
  Future<void> createPost(String caption, List<String> imagePaths);
  Stream<List<PostEntity>> getUserPostsStream(String userId);
}
