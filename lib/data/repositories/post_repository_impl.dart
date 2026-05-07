import 'package:checking_travel_app/data/datasources/post_remote_data_source.dart';
import 'package:checking_travel_app/domain/entities/post_entity.dart';
import 'package:checking_travel_app/domain/repositories/post_repository.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;

  PostRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<PostEntity>> getPostsStream() {
    return remoteDataSource.getPostsStream();
  }

  @override
  Future<void> createPost(String caption, List<String> imagePaths) async {
    await remoteDataSource.createPost(caption, imagePaths);
  }

  @override
  Stream<List<PostEntity>> getUserPostsStream(String userId) {
    return remoteDataSource.getUserPostsStream(userId);
  }
}
