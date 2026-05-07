import 'package:checking_travel_app/domain/entities/post_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel extends PostEntity {
  PostModel({
    required String id,
    required String userId,
    required String userName,
    required String userAvatar,
    required String caption,
    required List<String> imageUrls,
    DateTime? timestamp,
    required List<String> likes,
  }) : super(
          id: id,
          userId: userId,
          userName: userName,
          userAvatar: userAvatar,
          caption: caption,
          imageUrls: imageUrls,
          timestamp: timestamp,
          likes: likes,
        );

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Người dùng',
      userAvatar: data['userAvatar'] ?? '',
      caption: data['caption'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : null,
      likes: data['likes'] != null ? List<String>.from(data['likes']) : [],
    );
  }
}
