import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:talk_application/view/groupInfo.dart';

class GroupChats extends StatefulWidget {
  final String groupId;
  final String groupName;
  const GroupChats({required this.groupId, required this.groupName, super.key});

  @override
  State<GroupChats> createState() => _GroupChatsState();
}

class _GroupChatsState extends State<GroupChats> {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  TextEditingController messageController = TextEditingController();

  bool isLoading = true;

  onSendMessage() async {
    if (messageController.text.isNotEmpty) {
      Map<String, dynamic> chatData = {
        'sendby': firebaseAuth.currentUser!.displayName,
        'message': messageController.text,
        'type': 'text',
        'time': FieldValue.serverTimestamp(),
      };
      messageController.clear();
      await firebaseFirestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('chats')
          .add(chatData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          title: Column(
            children: [
              Text(
                widget.groupName,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const GroupInfo()));
                },
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
        body: Container(
          color: Colors.grey[100],
          child: Column(
            children: [
              Expanded(
                  child: StreamBuilder(
                stream: firebaseFirestore
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('chats')
                    .orderBy('time')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> chatMessage =
                              snapshot.data!.docs[index].data();
                          return messageTile(size, context, chatMessage);
                        });
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              )),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file,
                          color: Colors.deepPurple),
                      onPressed: () {
                        // Handle attach file action
                      },
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: TextField(
                          controller: messageController,
                          decoration: const InputDecoration(
                            hintText: "Type a message",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.deepPurple),
                      onPressed: () {
                        onSendMessage();
                        // Handle send message action
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Widget messageTile(
      Size size, BuildContext context, Map<String, dynamic> chatMessage) {
    bool isMe = firebaseAuth.currentUser!.displayName == chatMessage['sendby'];
    return chatMessage['type'] == 'text'
        ? Container(
            padding: EdgeInsets.only(
              left: isMe ? size.width * 0.25 : 8.0,
              right: isMe ? 8.0 : size.width * 0.25,
              top: 8.0,
              bottom: 8.0,
            ),
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isMe ? Colors.deepPurple : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(15),
                  topRight: const Radius.circular(15),
                  bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(15),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  isMe
                      ? const SizedBox()
                      : Text(
                          chatMessage['sendby'],
                          style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    chatMessage['message'],
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    chatMessage['time'] != null
                        ? DateFormat('hh:mm a')
                            .format((chatMessage['time'] as Timestamp).toDate())
                        : '',
                    textAlign: isMe ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        : chatMessage['type'] == 'img'
            ? Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: isMe ? Colors.deepPurple : Colors.grey[300],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(15),
                    topRight: const Radius.circular(15),
                    bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
                    bottomRight: isMe ? Radius.zero : const Radius.circular(15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      chatMessage['message'],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      chatMessage['time'] != null
                          ? DateFormat('hh:mm a').format(
                              (chatMessage['time'] as Timestamp).toDate())
                          : '',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            : chatMessage['type'] == 'notify'
                ? Container(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      bottom: 8.0,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent,
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            chatMessage['message'],
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox();
  }
}

class ShowImage extends StatelessWidget {
  final String imageUrl;
  const ShowImage({required this.imageUrl, super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        color: Colors.black,
        child: Image.network(imageUrl),
      ),
    );
  }
}
