import 'package:checking_travel_app/domain/entities/post_entity.dart';
import 'package:checking_travel_app/domain/repositories/post_repository.dart';

class GetUserPostsUseCase {
  final PostRepository repository;

  GetUserPostsUseCase(this.repository);

  // Truyền userId vào để chỉ lấy bài của người đó
  Stream<List<PostEntity>> execute(String userId) {
    return repository.getUserPostsStream(userId);
  }
}
