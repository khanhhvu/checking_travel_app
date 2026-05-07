class PostEntity {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String caption;
  final List<String> imageUrls;
  final DateTime? timestamp;
  final List<String> likes;

  PostEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.caption,
    required this.imageUrls,
    this.timestamp,
    required this.likes,
  });
}
