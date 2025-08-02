import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'group_chat_screen.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final String activityId;
  const ActivityDetailsScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  bool liked = false;
  bool joined = false;
  int totalLikes = 0;
  int totalJoined = 0;
  bool full = false;

  String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    checkInfo();
  }

  void checkInfo() async {
    var activityDoc = await FirebaseFirestore.instance
        .collection('activities')
        .doc(widget.activityId)
        .get();

    var likesDoc = await FirebaseFirestore.instance
        .collection('activities')
        .doc(widget.activityId)
        .collection('likes')
        .doc(userId)
        .get();

    var joinedDoc = await FirebaseFirestore.instance
        .collection('activities')
        .doc(widget.activityId)
        .collection('joinedUsers')
        .doc(userId)
        .get();

    var allJoined = await FirebaseFirestore.instance
        .collection('activities')
        .doc(widget.activityId)
        .collection('joinedUsers')
        .get();

    var maxCount = activityDoc['count'] ?? 0;

    setState(() {
      liked = likesDoc.exists;
      joined = joinedDoc.exists;
      totalLikes = activityDoc['likes'] ?? 0;
      totalJoined = allJoined.docs.length;
      full = totalJoined >= maxCount;
    });
  }

  String formatTime(Timestamp t) {
    var d = t.toDate();
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} - '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("تفاصيل النشاط")),
      body: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('activities')
            .doc(widget.activityId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: CircularProgressIndicator());
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          var creatorId = data['creatorId'];

          return FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(creatorId)
                .get(),
            builder: (context, userSnap) {
              if (!userSnap.hasData || userSnap.data == null) {
                return Center(child: CircularProgressIndicator());
              }

              var user = userSnap.data!.data() as Map<String, dynamic>;

              return Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: user['photoUrl'] != null
                              ? NetworkImage(user['photoUrl'])
                              : AssetImage('assets/images/profile.png')
                                    as ImageProvider,
                          radius: 24,
                        ),
                        SizedBox(width: 10),
                        Text(
                          user['name'], 
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // اسم النشاط
                    Text(
                      data['name'], 
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),


                    // وقت النشاط
                    Text('🕓 الوقت: ${formatTime(data['time'])}'),
                    SizedBox(height: 5),

                    // تاريخ الإنشاء
                    Text('📅 الإنشاء: ${formatTime(data['createdAt'])}'),
                    SizedBox(height: 10),

                    // عدد المنضمين
                    Text('👥 عدد المنضمين: $totalJoined'),
                    SizedBox(height: 20),

                    // أزرار اللايك والانضمام والدردشة
                    Row(
                      children: [
                        // زر اللايك
                        IconButton(
                          icon: Icon(
                            liked
                                ? Icons.thumb_up
                                : Icons.thumb_up_alt_outlined,
                            color: liked ? Colors.red : Colors.grey,
                          ),
                          onPressed: () async {
                            var ref = FirebaseFirestore.instance
                                .collection('activities')
                                .doc(widget.activityId)
                                .collection('likes')
                                .doc(userId);

                            if (liked) {
                              await ref.delete();
                              await FirebaseFirestore.instance
                                  .collection('activities')
                                  .doc(widget.activityId)
                                  .update({'likes': FieldValue.increment(-1)});
                              setState(() {
                                totalLikes--;
                                liked = false;
                              });
                            } else {
                              await ref.set({'likedAt': Timestamp.now()});
                              await FirebaseFirestore.instance
                                  .collection('activities')
                                  .doc(widget.activityId)
                                  .update({'likes': FieldValue.increment(1)});
                              setState(() {
                                totalLikes++;
                                liked = true;
                              });
                            }
                          },
                        ),

                        // عدد اللايكات    
                        GestureDetector(
                          onTap: () {
                          },
                          child: Text(
                            '$totalLikes الإعجابات',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),


                        Spacer(),
                      //زر الانضمام//
                         joined || userId == creatorId //اذا كان المستخدم الريدي بالنشاط او هو المنشئ يظهر له زر الدردشة
                            ? ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GroupChatScreen(
                                        activityId: widget.activityId,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                ),
                                child: Text('الدردشة'),
                              )

                              //اذا العدد مكتمل
                            : full
                            ? ElevatedButton(
                                onPressed: null,
                                child: Text('اكتمل العدد'),
                              )

                            : ElevatedButton(//هنا ينضم المستخدم
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('activities')
                                      .doc(widget.activityId)
                                      .collection('joinedUsers')
                                      .doc(userId)
                                      .set({'joinedAt': Timestamp.now()});

                                  setState(() {
                                    joined = true;
                                    totalJoined++;//عدد المنضمين+1
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('تم الانضمام للنشاط'),
                                    ),
                                  );
                                },
                                child: Text('انضم'),
                              ),
                      
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
