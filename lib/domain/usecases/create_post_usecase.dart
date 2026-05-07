import 'package:checking_travel_app/domain/repositories/post_repository.dart';

class CreatePostUseCase {
  final PostRepository repository;

  CreatePostUseCase(this.repository);

  Future<void> execute(String caption, List<String> imagePaths) {
    return repository.createPost(caption, imagePaths);
  }
}
