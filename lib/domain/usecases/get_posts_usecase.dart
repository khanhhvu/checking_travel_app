import 'package:checking_travel_app/domain/entities/post_entity.dart';
import 'package:checking_travel_app/domain/repositories/post_repository.dart';

class GetPostsUseCase {
  final PostRepository repository;

  GetPostsUseCase(this.repository);

  Stream<List<PostEntity>> execute() {
    return repository.getPostsStream();
  }
}
