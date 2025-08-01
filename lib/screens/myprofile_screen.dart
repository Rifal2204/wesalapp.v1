import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي'), centerTitle: true),
        body: const Center(child: Text('لم يتم تسجيل الدخول')),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('حدث خطأ في تحميل البيانات')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('لا يوجد بيانات للمستخدم')),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          backgroundColor: const Color(0xFFFBF8F0),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: const Text(
              'الملف الشخصي',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.amber),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.amber),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: Colors.amber.shade50,
                    backgroundImage: data['photoUrl'] != null
                        ? NetworkImage(data['photoUrl'])
                        : const AssetImage('assets/images/profile.png') as ImageProvider,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  data['name'] ?? 'بدون اسم',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data['email'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 24),

                // ✅ الإحصائيات الحقيقية (عدد الأنشطة المنشئة والمنضم لها)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('activities')
                      .where('userId', isEqualTo: user.uid)
                      .snapshots(),
                  builder: (context, createdSnapshot) {
                    final createdCount = createdSnapshot.data?.docs.length ?? 0;

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collectionGroup('joinedUsers')
                          .where(FieldPath.documentId, isEqualTo: user.uid)
                          .snapshots(),
                      builder: (context, joinedSnapshot) {
                        final joinedCount = joinedSnapshot.data?.docs.length ?? 0;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ProfileStat(title: 'الأنشطة المنشئة', value: '$createdCount'),
                            _ProfileStat(title: 'الأنشطة المنضم لها', value: '$joinedCount'),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 32),

                // ✅ عرض البايو (إذا موجود فقط)
                if ((data['bio'] ?? '').isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      data['bio'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Cairo',
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 32),

                // ✅ عرض الأنشطة التي أنشأها المستخدم
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('activities')
                      .where('userId', isEqualTo: user.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, activitySnapshot) {
                    if (activitySnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (activitySnapshot.hasError) {
                      return Center(
                          child: Text('حدث خطأ في تحميل الأنشطة: ${activitySnapshot.error}'));
                    }

                    if (!activitySnapshot.hasData || activitySnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('لا توجد أنشطة حتى الآن'));
                    }

                    final activities = activitySnapshot.data!.docs;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الأنشطة الخاصة بي',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...activities.map((doc) {
                          final actData = doc.data()! as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: actData['imagePath'] != null
                                  ? Image.network(
                                      actData['imagePath'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.sports, color: Colors.amber),
                              title: Text(actData['name'] ?? 'بدون اسم'),
                              subtitle: Text(
                                actData['time'] != null
                                    ? (actData['time'] as Timestamp)
                                        .toDate()
                                        .toLocal()
                                        .toString()
                                    : 'بدون وقت',
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String title;
  final String value;
  const _ProfileStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}
