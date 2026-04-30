import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetreck/core/bloc/view_status.dart';
import 'package:vibetreck/core/network/network_status_provider.dart';
import 'package:vibetreck/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:vibetreck/features/feed/data/feed_repository.dart';
import 'package:vibetreck/shared/models/feed_comment.dart';
import 'package:vibetreck/shared/models/feed_post.dart';

class FeedState {
  const FeedState({
    this.status = ViewStatus.initial,
    this.posts = const [],
    this.errorMessage,
  });

  final ViewStatus status;
  final List<FeedPost> posts;
  final String? errorMessage;

  FeedState copyWith({
    ViewStatus? status,
    List<FeedPost>? posts,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FeedState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class FeedCubit extends Cubit<FeedState> {
  FeedCubit({
    required FeedRepository repository,
    required ConnectivityCubit connectivityCubit,
    required AuthCubit authCubit,
  })  : _repository = repository,
        _connectivityCubit = connectivityCubit,
        _authCubit = authCubit,
        super(const FeedState());

  final FeedRepository _repository;
  final ConnectivityCubit _connectivityCubit;
  final AuthCubit _authCubit;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: ViewStatus.loading,
        clearError: true,
      ),
    );
    try {
      final posts = await _repository.fetchPosts();
      emit(state.copyWith(status: ViewStatus.success, posts: posts, clearError: true));
    } catch (error) {
      emit(state.copyWith(status: ViewStatus.failure, errorMessage: error.toString()));
    }
  }

  Future<void> refresh() => load();

  List<FeedPost> postsForUser(String userId) {
    return state.posts.where((post) => post.userId == userId).toList();
  }

  Future<void> createPost({
    required String sessionId,
    required String imageUrl,
    required String caption,
    required Map<String, dynamic> statsJson,
  }) async {
    _ensureOnline();
    final user = _authCubit.state.user;
    if (user == null) throw Exception('User not found');
    final post = FeedPost(
      id: 'p-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(999)}',
      userId: user.id,
      sessionId: sessionId,
      imageUrl: imageUrl,
      caption: caption,
      statsJson: statsJson,
      createdAt: DateTime.now(),
      likeCount: 0,
      commentCount: 0,
      username: user.email.split('@').first,
      likedByMe: false,
    );
    await _repository.createPost(post);
    await load();
  }

  Future<void> updatePost(FeedPost post) async {
    _ensureOnline();
    await _repository.updatePost(post);
    await load();
  }

  Future<void> deletePost(String postId) async {
    _ensureOnline();
    await _repository.deletePost(postId);
    await load();
  }

  Future<void> toggleLike(String postId) async {
    _ensureOnline();
    final updated = await _repository.likePost(postId);
    final nextPosts = state.posts
        .map((post) => post.id == postId ? updated : post)
        .toList(growable: false);
    emit(state.copyWith(posts: nextPosts));
  }

  void _ensureOnline() {
    if (!_connectivityCubit.state) {
      throw Exception('No internet connection.');
    }
  }
}

class FeedPostDetailState {
  const FeedPostDetailState({
    this.status = ViewStatus.initial,
    this.post,
    this.comments = const [],
    this.errorMessage,
    this.isSubmittingComment = false,
  });

  final ViewStatus status;
  final FeedPost? post;
  final List<FeedComment> comments;
  final String? errorMessage;
  final bool isSubmittingComment;

  FeedPostDetailState copyWith({
    ViewStatus? status,
    FeedPost? post,
    List<FeedComment>? comments,
    String? errorMessage,
    bool? isSubmittingComment,
    bool clearError = false,
  }) {
    return FeedPostDetailState(
      status: status ?? this.status,
      post: post ?? this.post,
      comments: comments ?? this.comments,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSubmittingComment: isSubmittingComment ?? this.isSubmittingComment,
    );
  }
}

class FeedPostDetailCubit extends Cubit<FeedPostDetailState> {
  FeedPostDetailCubit({
    required String postId,
    required FeedRepository repository,
    required ConnectivityCubit connectivityCubit,
    required FeedCubit feedCubit,
  })  : _postId = postId,
        _repository = repository,
        _connectivityCubit = connectivityCubit,
        _feedCubit = feedCubit,
        super(const FeedPostDetailState());

  final String _postId;
  final FeedRepository _repository;
  final ConnectivityCubit _connectivityCubit;
  final FeedCubit _feedCubit;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading, clearError: true));
    try {
      final results = await Future.wait([
        _repository.fetchPost(_postId),
        _repository.fetchComments(_postId),
      ]);
      emit(
        state.copyWith(
          status: ViewStatus.success,
          post: results[0] as FeedPost,
          comments: results[1] as List<FeedComment>,
          isSubmittingComment: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: ViewStatus.failure, errorMessage: error.toString()));
    }
  }

  Future<void> updatePost(FeedPost post) async {
    _ensureOnline();
    final updated = await _repository.updatePost(post);
    emit(state.copyWith(post: updated));
    await _feedCubit.load();
  }

  Future<void> deletePost() async {
    _ensureOnline();
    await _repository.deletePost(_postId);
    await _feedCubit.load();
  }

  Future<void> toggleLike() async {
    _ensureOnline();
    final updated = await _repository.likePost(_postId);
    emit(state.copyWith(post: updated));
    await _feedCubit.load();
  }

  Future<void> addComment(String body) async {
    _ensureOnline();
    emit(state.copyWith(isSubmittingComment: true, clearError: true));
    try {
      await _repository.addComment(_postId, body.trim());
      await load();
      await _feedCubit.load();
    } catch (error) {
      emit(state.copyWith(isSubmittingComment: false, errorMessage: error.toString()));
      rethrow;
    }
  }

  void _ensureOnline() {
    if (!_connectivityCubit.state) {
      throw Exception('No internet connection.');
    }
  }
}
