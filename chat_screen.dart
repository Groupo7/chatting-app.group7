import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverEmail;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverEmail,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentId = FirebaseAuth.instance.currentUser!.uid;

  String getRoomId() {
    List<String> ids = [currentId, widget.receiverId];
    ids.sort();
    return ids.join("_");
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String msg = _messageController.text.trim();
    _messageController.clear();

    String roomId = getRoomId();

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'senderId': currentId,
      'message': msg,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).set({
      'participants': [currentId, widget.receiverId],
      'lastMessage': msg,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    String roomId = getRoomId();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.purple),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.receiverEmail,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(roomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index];
                    bool isMe = data['senderId'] == currentId;

                    Timestamp? t = data['timestamp'];
                    String time = t != null
                        ? DateFormat('HH:mm').format(t.toDate())
                        : "";

                    return Row(
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Avatar for receiver
                        if (!isMe)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.purple,
                              child: Icon(Icons.person,
                                  size: 18, color: Colors.white),
                            ),
                          ),

                        Flexible(
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.purple
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  data['message'],
                                  style: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : Colors.black),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  time,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.black54),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.grey.shade200,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type message...",
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            backgroundColor: Colors.purple,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_upward, // 🔥 mshale wa kutuma
                color: Colors.white,
              ),
              onPressed: _sendMessage,
            ),
          )
        ],
      ),
    );
  }
}
