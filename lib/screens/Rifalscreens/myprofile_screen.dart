import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'settings_screen.dart';
import 'activity_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String selectedTab = 'created';

  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> activities = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadUserDataAndActivities();
  }

  Future<List<Map<String, dynamic>>> getJoinedActivities(String userId) async {
    final activitiesQuery = await FirebaseFirestore.instance.collection('activities').get();

    List<Map<String, dynamic>> joinedActivities = [];

    for (var doc in activitiesQuery.docs) {
      final joinedUserDoc = await doc.reference.collection('joinedUsers').doc(userId).get();
      if (joinedUserDoc.exists) {
        var data = doc.data();
        data['id'] = doc.id;
        joinedActivities.add(data);
      }
    }

    return joinedActivities;
  }

  Future<void> loadUserDataAndActivities() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final user = FirebaseAuth.instance.currentUser;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

      if (!userDoc.exists) {
        setState(() {
          errorMessage = 'لا يوجد بيانات للمستخدم';
          isLoading = false;
        });
        return;
      }
      userData = userDoc.data();

      if (selectedTab == 'created') {
        final activitiesQuery = await FirebaseFirestore.instance
            .collection('activities')
            .where('creatorId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();

        activities = activitiesQuery.docs.map((doc) {
          var d = doc.data();
          d['id'] = doc.id;
          return d;
        }).toList();
      } else {
        // جلب الأنشطة التي انضم إليها المستخدم
        activities = await getJoinedActivities(user.uid);
      }

      setState(() {
        isLoading = false;
        errorMessage = '';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'حدث خطأ أثناء التحميل';
        isLoading = false;
      });
    }
  }

  void switchTab(String tab) {
    if (tab == selectedTab) return;
    selectedTab = tab;
    activities = [];
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    loadUserDataAndActivities();
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'بدون وقت';
    final date = timestamp.toDate().toLocal();
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('الملف الشخصي')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('الملف الشخصي')),
        body: Center(child: Text(errorMessage)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('الملف الشخصي'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: userData != null && userData!['photoUrl'] != null
                  ? NetworkImage(userData!['photoUrl'])
                  : AssetImage('assets/images/profile.png') as ImageProvider,
            ),
            SizedBox(height: 10),
            Text(
              userData?['name'] ?? '',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            if (userData?['bio'] != null && userData!['bio'].toString().trim().isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Text(
      userData!['bio'],
      style: TextStyle(
        color: Colors.grey[700],
        fontSize: 16,
      ),
      textAlign: TextAlign.center,
    ),
  ),

            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => switchTab('created'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedTab == 'created' ? Colors.amber : Colors.grey[300],
                  ),
                  child: Text(
                    'الأنشطة المنشأة',
                    style: TextStyle(color: selectedTab == 'created' ? Colors.white : Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => switchTab('joined'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedTab == 'joined' ? Colors.amber : Colors.grey[300],
                  ),
                  child: Text(
                    'الأنشطة المنضم لها',
                    style: TextStyle(color: selectedTab == 'joined' ? Colors.white : Colors.black),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            activities.isEmpty
                ? Text('لا توجد أنشطة')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      var data = activities[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: data['imagePath'] != null
                              ? Image.network(data['imagePath'], width: 50, height: 50, fit: BoxFit.cover)
                              : Icon(Icons.local_activity, color: Colors.amber),
                          title: Text(data['name'] ?? ''),
                          subtitle: Text(formatTimestamp(data['createdAt'] as Timestamp?)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActivityDetailsScreen(activityId: data['id']),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
