class CommentEntity {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime? timestamp;

  CommentEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    this.timestamp,
  });
}