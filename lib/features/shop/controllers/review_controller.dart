import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/features/shop/models/review_model.dart';

class ReviewController extends GetxController {
  static ReviewController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── State ──────────────────────────────────────────────────────────────
  final RxList<ReviewModel> reviews = <ReviewModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  // Add-review form state
  final RxDouble selectedRating = 0.0.obs;
  final TextEditingController commentController = TextEditingController();

  // Computed stats (plain getters — reactive because they read `reviews` which is Rx)
  double get avgRating {
    if (reviews.isEmpty) return 0.0;
    final sum = reviews.fold<double>(0, (s, r) => s + r.rating);
    return sum / reviews.length;
  }

  int get reviewCount => reviews.length;

  /// Returns a map of star-value → count (keys 1..5)
  Map<int, int> get ratingCounts {
    final counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in reviews) {
      final star = r.rating.round().clamp(1, 5);
      counts[star] = (counts[star] ?? 0) + 1;
    }
    return counts;
  }

  // ── Fetch ───────────────────────────────────────────────────────────────
  Future<void> fetchReviews(String productId) async {
    try {
      isLoading.value = true;
      reviews.clear();

      final snap = await _db
          .collection('Products')
          .doc(productId)
          .collection('Reviews')
          .orderBy('createdAt', descending: true)
          .get();

      reviews.assignAll(
        snap.docs.map((doc) => ReviewModel.fromSnapshot(doc)).toList(),
      );
    } catch (e) {
      debugPrint('ReviewController.fetchReviews error: $e');
      Get.snackbar(
        'Error',
        'Could not load reviews: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Submit ──────────────────────────────────────────────────────────────
  Future<void> submitReview(String productId) async {
    if (selectedRating.value == 0) {
      Get.snackbar(
        'Rating required',
        'Please select a star rating.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final comment = commentController.text.trim();
    if (comment.isEmpty) {
      Get.snackbar(
        'Comment required',
        'Please write a short comment.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar(
        'Not signed in',
        'Please sign in to leave a review.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isSubmitting.value = true;

      // Resolve user display name: prefer Firestore Users doc, then Auth profile
      String userName = 'Anonymous';
      String? userImage = user.photoURL;
      try {
        final userDoc = await _db.collection('Users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final first = (data['FirstName'] ?? '').toString().trim();
          final last = (data['LastName'] ?? '').toString().trim();
          final fullName = '$first $last'.trim();
          if (fullName.isNotEmpty) userName = fullName;
          final storedImage = (data['ProfilePicture'] ?? '').toString();
          if (storedImage.isNotEmpty) userImage = storedImage;
        }
      } catch (_) {
        // Fallback to Auth profile
      }
      if (userName == 'Anonymous') {
        userName =
            user.displayName ?? user.email?.split('@').first ?? 'Anonymous';
      }

      final review = ReviewModel(
        id: '',
        productId: productId,
        userId: user.uid,
        userName: userName,
        userImage: userImage,
        rating: selectedRating.value,
        comment: comment,
        createdAt: DateTime.now(),
      );

      final productRef = _db.collection('Products').doc(productId);
      final reviewRef = productRef.collection('Reviews').doc();

      // Atomic: write review + update product avgRating & reviewCount
      await _db.runTransaction((tx) async {
        final productSnap = await tx.get(productRef);
        final oldCount = ((productSnap.data()?['reviewCount']) ?? 0) as num;
        final oldAvg = ((productSnap.data()?['avgRating']) ?? 0.0) as num;
        final newCount = oldCount.toInt() + 1;
        final newAvg =
            ((oldAvg.toDouble() * oldCount.toInt()) + review.rating) / newCount;

        tx.set(reviewRef, review.toMap());
        tx.update(productRef, {'avgRating': newAvg, 'reviewCount': newCount});
      });

      // Add locally so UI updates without re-fetching
      reviews.insert(
        0,
        ReviewModel(
          id: reviewRef.id,
          productId: productId,
          userId: review.userId,
          userName: review.userName,
          userImage: review.userImage,
          rating: review.rating,
          comment: review.comment,
          createdAt: review.createdAt,
        ),
      );

      // Reset form
      selectedRating.value = 0.0;
      commentController.clear();

      Get.snackbar(
        'Thank you!',
        'Your review has been submitted.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('ReviewController.submitReview error: $e');
      Get.snackbar(
        'Error',
        'Could not submit review: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }
}
