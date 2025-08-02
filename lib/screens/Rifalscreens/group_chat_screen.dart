import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupChatScreen extends StatefulWidget {
  final String activityId;

  const GroupChatScreen({super.key, required this.activityId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final controller = TextEditingController();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  Map<String, Map<String, dynamic>> usersData = {};
  bool isUsersLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsersData();
  }

  Future<void> loadUsersData() async {
    final chatSnapshot = await FirebaseFirestore.instance
        .collection('activities')
        .doc(widget.activityId)
        .collection('chat')
        .get();

    final userIds = chatSnapshot.docs.map((doc) => doc['senderId'] as String).toSet();

    for (String id in userIds) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(id).get();
      if (userDoc.exists) {
        usersData[id] = userDoc.data()!;
      } else {
        usersData[id] = {'name': 'بدون اسم', 'photoUrl': null};
      }
    }

    setState(() {
      isUsersLoading = false;
    });
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('activities')
        .doc(widget.activityId)
        .collection('chat')
        .add({
      'senderId': userId,
      'message': text,
      'timestamp': Timestamp.now(),
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دردشة النشاط')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('activities')
                  .doc(widget.activityId)
                  .collection('chat')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || isUsersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == userId;

                    final senderData = usersData[msg['senderId']] ?? {'name': 'بدون اسم', 'photoUrl': null};
                    final senderName = senderData['name'];
                    final senderPhotoUrl = senderData['photoUrl'];

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.amber : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              CircleAvatar(
                                radius: 15,
                                backgroundImage: senderPhotoUrl != null ? NetworkImage(senderPhotoUrl) : null,
                                child: senderPhotoUrl == null ? const Icon(Icons.person, size: 18) : null,
                              ),
                            if (!isMe) const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  senderName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(msg['message']),
                              ],
                            ),
                            if (isMe) const SizedBox(width: 8),
                            if (isMe)
                              CircleAvatar(
                                radius: 15,
                                backgroundImage: senderPhotoUrl != null ? NetworkImage(senderPhotoUrl) : null,
                                child: senderPhotoUrl == null ? const Icon(Icons.person, size: 18) : null,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالة...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
