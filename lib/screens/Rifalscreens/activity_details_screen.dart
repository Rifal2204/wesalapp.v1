import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'group_chat_screen.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final String activityId;
  const ActivityDetailsScreen({super.key, required this.activityId, required Map<String, dynamic> activityData});// يتمرر من الشاشة اللي قبل

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  //تعريف المتغيرات اللي بتظهر في الودجت//
  bool liked = false;
  bool joined = false;
  int totalLikes = 0;
  int totalJoined = 0;
  bool full = false;

  String userId = FirebaseAuth.instance.currentUser!.uid;// اي دي المستخدم حاليا

  @override
  void initState() {
    super.initState();
    checkInfo();
  }
//--------------جلب بيانات الاكتفيتي من الفايربيس---------//

  void checkInfo() async {
    var activityDoc = await FirebaseFirestore.instance
        .collection('activities')
        .doc(widget.activityId)//الاي دي اللي تمرر من الصفحة اللي قبلها
        .get();

//------------جلب اللايكات---//
    var likesDoc = await FirebaseFirestore.instance
        .collection('activities')
        .doc(widget.activityId)
        .collection('likes')
        .doc(userId)//اي دي المستخدم -سبق تعريفه فوق
        .get();

//-------هنا لتحديد المستخدم منظم للاكتفيتي ولا-----//
    var joinedDoc = await FirebaseFirestore.instance
        .collection('activities')
        .doc(widget.activityId)
        .collection('joinedUsers')
        .doc(userId)
        .get();
//-----------هنا جلب بيانات المنضمين //
    var allJoined = await FirebaseFirestore.instance
        .collection('activities')
        .doc(widget.activityId)
        .collection('joinedUsers')
        .get();

    var maxCount = activityDoc['count'] ?? 0;//اقصى عدد للمنضمين 

//هنا تحديث الحالة عشان تظهر لي بالواجهة------//
    setState(() {
      liked = likesDoc.exists;
      joined = joinedDoc.exists;
      totalLikes = activityDoc['likes'] ?? 0;
      totalJoined = allJoined.docs.length;
      full = totalJoined >= maxCount;
    });
  }
//------عرض قائمة اعضاء للنشاط-------------//
  void showJoinedUsersDialog() async {
    final joinedUsersSnapshot = await FirebaseFirestore.instance
        .collection('activities')
        .doc(widget.activityId)
        .collection('joinedUsers')
        .get();

    List<String> userIds = joinedUsersSnapshot.docs.map((doc) => doc.id).toList();//حفظ قائمة المنضمين

    if (userIds.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: userIds)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final users = snapshot.data!.docs;

          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('المنضمون للنشاط', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                ...users.map((userDoc) {
                  final user = userDoc.data();
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user['photoUrl'] != null
                          ? NetworkImage(user['photoUrl'])
                          : AssetImage('assets/images/profile.png') as ImageProvider,
                    ),
                    title: Text(user['name'] ?? 'بدون اسم'),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
//تنسيق الوقت
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
                    Text(
                      data['name'],
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text('🕓 الوقت: ${formatTime(data['time'])}'),
                    SizedBox(height: 5),
                    Text('📅 الإنشاء: ${formatTime(data['createdAt'])}'),
                    SizedBox(height: 10),

                    // 👥 عدد المنضمين
                    GestureDetector(
                      onTap: showJoinedUsersDialog,
                      child: Text(
                        '👥 عدد المنضمين: $totalJoined',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    Row(
                      children: [

                        //----------زر اللايك-----------------

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
                        Text(
                          '$totalLikes الإعجابات',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        Spacer(),

                        //   زر الانضمام أو الدردشة حسب الحالة
                        joined || userId == creatorId
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
                                child: Text('الدردشة',
                                style: TextStyle(
                                  color:Colors.white,
                                  fontSize: 20,
                                  
                                ),),
                              )
                            : full
                                ? ElevatedButton(
                                    onPressed: null,
                                    child: Text('اكتمل العدد'),
                                  )
                                : ElevatedButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('activities')
                                          .doc(widget.activityId)
                                          .collection('joinedUsers')
                                          .doc(userId)
                                          .set({'joinedAt': Timestamp.now()});

                                      setState(() {
                                        joined = true;
                                        totalJoined++;
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
