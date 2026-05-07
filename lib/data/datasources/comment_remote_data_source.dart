import 'package:checking_travel_app/domain/entities/comment_entity.dart';
import 'package:checking_travel_app/domain/repositories/comment_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- MODEL ---
class CommentModel extends CommentEntity {
  CommentModel({
    required super.id, required super.userId, required super.userName,
    required super.userAvatar, required super.content, super.timestamp
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Người dùng',
      userAvatar: data['userAvatar'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : null,
    );
  }
}

// --- DATA SOURCE & REPOSITORY IMPL ---
class CommentRepositoryImpl implements CommentRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  CommentRepositoryImpl(this.firestore, this.firebaseAuth);

  @override
  Stream<List<CommentEntity>> getCommentsStream(String postId) {
    return firestore
        .collection('posts')
        .doc(postId)
        .collection('comments') // Truy cập vào subcollection 'comments'
        .orderBy('timestamp', descending: false) // Bình luận cũ ở trên, mới ở dưới
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList());
  }

  @override
  Future<void> addComment(String postId, String content) async {
    User? user = firebaseAuth.currentUser;
    if (user == null || content.trim().isEmpty) return;

    // 1. Lưu bình luận vào bài viết
    await firestore.collection('posts').doc(postId).collection('comments').add({
      'userId': user.uid,
      'userName': user.displayName ?? 'Người dùng',
      'userAvatar': user.photoURL ?? '',
      'content': content.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Lấy thông tin bài viết để biết ai là chủ
    DocumentSnapshot postDoc = await firestore.collection('posts').doc(postId).get();
    if (postDoc.exists) {
      String postOwnerId = postDoc['userId'];

      // 3. THÔNG BÁO (Nếu người bình luận không phải chủ bài viết)
      if (user.uid != postOwnerId) {
        await firestore.collection('users').doc(postOwnerId).collection('notifications').add({
          'type': 'comment', // Loại thông báo: Bình luận
          'content': content.trim(), // Lưu kèm nội dung bình luận
          'senderId': user.uid,
          'senderName': user.displayName ?? 'Người dùng',
          'senderAvatar': user.photoURL ?? '',
          'postId': postId,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    }
  }
}