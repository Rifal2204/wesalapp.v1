import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/image_db.dart';

class AllActivitiesScreen extends StatelessWidget {
  const AllActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('جميع الأنشطة'),
        backgroundColor: Colors.blue.shade400,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('activities')
                .where(
                  'time',
                  isGreaterThanOrEqualTo: DateTime(
                    today.year,
                    today.month,
                    today.day,
                  ),
                )
                .orderBy('time')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد أنشطة حالياً.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'نشاط';
              final location = data['location'] ?? 'غير معروف';
              final time = (data['time'] as Timestamp).toDate();
              final imageId = data['imageId'] as int?;

              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final tomorrow = today.add(const Duration(days: 1));
              final activityDay = DateTime(time.year, time.month, time.day);

              String dayLabel;
              if (activityDay == today) {
                dayLabel = 'اليوم';
              } else if (activityDay == tomorrow) {
                dayLabel = 'غداً';
              } else {
                dayLabel = DateFormat.EEEE('ar').format(activityDay);
              }

              final formattedTime =
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              final displayTime = '$dayLabel الساعة $formattedTime';

              return FutureBuilder<Uint8List?>(
                future: imageId != null ? ImageDB.getImage(imageId) : null,
                builder: (context, imageSnapshot) {
                  Widget? imageWidget;
                  if (imageSnapshot.connectionState == ConnectionState.done &&
                      imageSnapshot.hasData) {
                    imageWidget = ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        imageSnapshot.data!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageWidget != null) ...[
                          imageWidget,
                          const SizedBox(height: 12),
                        ],
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(displayTime),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
