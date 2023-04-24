import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:seyaqti_app/widgets/loading.dart';
import 'package:seyaqti_app/shared_import.dart';

class ManageReview extends StatefulWidget {
  const ManageReview({super.key, required this.instructorID});
  final String instructorID;
  @override
  State<ManageReview> createState() => _ManageReviewState();
}

class _ManageReviewState extends State<ManageReview> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final commentController = TextEditingController();
  final traineeID = AppUser.currentUser!.id!;
  final imageURL = AppUser.currentUser!.imageURL;
  final displayName = AppUser.currentUser!.fullName()!;

  bool isEditing = false;
  bool isLoading = true;
  double rating = 0;

  @override
  void initState() {
    super.initState();
    getPreviousReview();
  }

  DocumentReference<Review> getReviewDoc() {
    final instructorID = widget.instructorID;
    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(instructorID)
        .collection('reviews')
        .doc(traineeID);
    return doc.withConverter(
      fromFirestore: (snapshot, _) => Review.fromJson(snapshot.data()!),
      toFirestore: (review, _) => review.toJson(),
    );
  }

  DocumentReference<AppUser> getInstructorDoc() {
    final instructorID = widget.instructorID;
    final doc =
        FirebaseFirestore.instance.collection('users').doc(instructorID);
    return doc.withConverter(
      fromFirestore: (snapshot, options) => AppUser.fromJson(snapshot.data()!),
      toFirestore: (user, options) => user.toJson(),
    );
  }

  CollectionReference<Review> getReviewCollection() {
    final instructorID = widget.instructorID;
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(instructorID)
        .collection('reviews');
    return collection.withConverter(
      fromFirestore: (snapshot, _) => Review.fromJson(snapshot.data()!),
      toFirestore: (review, _) => review.toJson(),
    );
  }

  Future getPreviousReview() async {
    try {
      final snapshot = await getReviewDoc().get();
      if (snapshot.exists) {
        final review = snapshot.data()!;
        isEditing = true;
        titleController.text = review.title!;
        commentController.text = review.comment!;
        rating = review.rating!;
      }
      isLoading = false;
      setState(() {});
    } on FirebaseException catch (_) {
      debugPrint(_.message);
    }
  }

  Future updateReview() async {
    try {
      setState(() {
        isLoading = true;
      });
      final title = titleController.text.trim();
      final comment = commentController.text.trim();
      final review = Review(
        title: title,
        comment: comment,
        rating: rating,
        imageURL: imageURL,
        instructorID: widget.instructorID,
        traineeID: traineeID,
        displayName: displayName,
      );
      await getReviewDoc().set(review);
      await setRatingAvg();
      isEditing
          ? Utils.ShowSuccessBar('Review modified successfully.')
          : Utils.ShowSuccessBar('Review added successfully.');
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseException catch (_) {
      debugPrint(_.message);
      Utils.ShowErrorBar('Something went wrong...');
      Navigator.pop(context);
    }
  }

  Future setRatingAvg() async {
    final reviews = await getReviewCollection().get();
    double sum = 0;
    for (var doc in reviews.docs) {
      final review = doc.data();
      sum += review.rating!;
    }
    final count = reviews.docs.length;
    final average = sum / count;
    await getInstructorDoc().update({
      'ratingAverage': average,
      'ratingCount': count,
    });
  }

  Future deleteReview() async {
    FocusScope.of(context).unfocus();
    try {
      setState(() {
        isLoading = true;
      });
      await getReviewDoc().delete();
      await setRatingAvg();
      Utils.ShowSuccessBar('Review deleted successfully.');
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseException catch (_) {
      debugPrint(_.message);
      Utils.ShowErrorBar('Something went wrong...');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      onTapDown: (_) => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
            title: Text(isEditing ? 'Edit Review' : 'Add Review'),
            centerTitle: true),
        body: isLoading
            ? const Loading(color: Colors.white10)
            : Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Text(
                        'Rating: $rating',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 20),
                      RatingBar.builder(
                        initialRating: rating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, _) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        updateOnDrag: true,
                        onRatingUpdate: (rating) {
                          setState(() => this.rating = rating);
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        textCapitalization: TextCapitalization.sentences,
                        autocorrect: true,
                        enableSuggestions: true,
                        controller: titleController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.title),
                          labelText: 'Title',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Title cannot be empty.';
                          } else if (value.length > 60) {
                            return 'Title is too long.';
                          } else {
                            return null;
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        maxLines: 5,
                        minLines: 1,
                        maxLength: 200,
                        textCapitalization: TextCapitalization.sentences,
                        autocorrect: true,
                        enableSuggestions: true,
                        controller: commentController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.comment),
                          labelText: 'Comment',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Comment cannot be empty.';
                          } else if (value.length > 200) {
                            return 'Comment is too long.';
                          } else if (rating < 1) {
                            return 'Star rating is required';
                          } else {
                            return null;
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          minimumSize: const Size.fromHeight(40),
                        ),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          final isValid = formKey.currentState!.validate();
                          if (isValid) {
                            debugPrint('Valid Submit');
                            updateReview();
                          }
                        },
                        child: Text(isEditing ? 'SAVE CHANGES' : 'ADD REVIEW'),
                      ),
                      const SizedBox(height: 5),
                      OutlinedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          minimumSize: const Size.fromHeight(40),
                        ),
                        onPressed: isEditing ? deleteReview : null,
                        child: const Text('DISCARD REVIEW'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
