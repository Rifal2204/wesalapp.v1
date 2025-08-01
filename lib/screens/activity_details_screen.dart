import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'group_chat_screen.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final String activityId;

  const ActivityDetailsScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  bool hasLiked = false;
  bool isJoined = false;

  final userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _checkUserInteraction();
  }

  Future<void> _checkUserInteraction() async {
    final doc = await FirebaseFirestore.instance
        .collection('activities')
        .doc(widget.activityId)
        .collection('likes')
        .doc(userId)
        .get();

    final joinedDoc = await FirebaseFirestore.instance
        .collection('activities')
        .doc(widget.activityId)
        .collection('joinedUsers')
        .doc(userId)
        .get();

    setState(() {
      hasLiked = doc.exists;
      isJoined = joinedDoc.exists;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F0),
      appBar: AppBar(
        title: const Text('تفاصيل النشاط'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('activities')
            .doc(widget.activityId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'] ?? 'بدون اسم', style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 10),
                Text('التاريخ: ${(data['time'] as Timestamp).toDate()}'),
                const SizedBox(height: 10),
                Text(data['description'] ?? 'لا يوجد وصف'),
                const SizedBox(height: 20),

                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: isJoined
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GroupChatScreen(activityId: widget.activityId),
                                ),
                              );
                            }
                          : () async {
                              await FirebaseFirestore.instance
                                  .collection('activities')
                                  .doc(widget.activityId)
                                  .collection('joinedUsers')
                                  .doc(userId)
                                  .set({'joinedAt': Timestamp.now()});

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .update({
                                'joinedActivitiesCount': FieldValue.increment(1),
                              });

                              setState(() {
                                isJoined = true;
                              });
                            },
                      icon: const Icon(Icons.group),
                      label: Text(isJoined ? 'الدردشة' : 'انضم'),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('favorites')
                            .doc(widget.activityId)
                            .set({'savedAt': Timestamp.now()});
                      },
                      icon: const Icon(Icons.favorite_border),
                    ),
                    IconButton(
                      onPressed: () async {
                        final likeRef = FirebaseFirestore.instance
                            .collection('activities')
                            .doc(widget.activityId)
                            .collection('likes')
                            .doc(userId);

                        if (hasLiked) {
                          await likeRef.delete();
                          await FirebaseFirestore.instance
                              .collection('activities')
                              .doc(widget.activityId)
                              .update({'likes': FieldValue.increment(-1)});
                        } else {
                          await likeRef.set({'likedAt': Timestamp.now()});
                          await FirebaseFirestore.instance
                              .collection('activities')
                              .doc(widget.activityId)
                              .update({'likes': FieldValue.increment(1)});
                        }

                        setState(() {
                          hasLiked = !hasLiked;
                        });
                      },
                      icon: Icon(
                        hasLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        color: hasLiked ? Colors.amber : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
