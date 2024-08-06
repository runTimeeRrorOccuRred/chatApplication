import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ChatRoom extends StatefulWidget {
  final Map<String, dynamic>? userMap;
  final String? chatRoomId;

  ChatRoom({this.userMap, this.chatRoomId});

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final TextEditingController messageController = TextEditingController();
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  File? imageFile;

  Future<void> getImage() async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      final XFile? xFile =
          await imagePicker.pickImage(source: ImageSource.gallery);
      if (xFile != null && xFile.path.isNotEmpty) {
        final File imageFile = File(xFile.path);
        await uploadImage(imageFile);
      } else {
        print('No image selected or path is empty.');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> uploadImage(File imageFile) async {
    int status = 1;
    try {
      final String fileName = const Uuid().v1();
      await FirebaseFirestore.instance
          .collection('chatroom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .doc(fileName)
          .set({
        "sendby": firebaseAuth.currentUser!.displayName,
        "message": "",
        "type": "img",
        "time": FieldValue.serverTimestamp()
      });

      final Reference ref =
          FirebaseStorage.instance.ref().child('images').child('$fileName.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);

      // Handling the result of the upload task
      uploadTask.whenComplete(() async {
        if (status == 1) {
          final String imageUrl = await ref.getDownloadURL();
          await FirebaseFirestore.instance
              .collection('chatroom')
              .doc(widget.chatRoomId)
              .collection('chats')
              .doc(fileName)
              .update({'message': imageUrl});
        }
      }).catchError((onError) async {
        await FirebaseFirestore.instance
            .collection('chatroom')
            .doc(widget.chatRoomId)
            .collection('chats')
            .doc(fileName)
            .delete();
        status = 0;
        print('Error uploading image: $onError');
      });
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  void onSendMessage() async {
    if (widget.chatRoomId != null && widget.chatRoomId!.isNotEmpty) {
      if (messageController.text.isNotEmpty) {
        Map<String, dynamic> messages = {
          "sendby": firebaseAuth.currentUser!.displayName,
          "type": "text",
          "message": messageController.text,
          "time": FieldValue.serverTimestamp(),
        };
        await firebaseFirestore
            .collection('chatroom')
            .doc(widget.chatRoomId)
            .collection('chats')
            .add(messages);
        messageController.clear();
        print("Message sent: $messages");
      } else {
        print("Please enter some text");
      }
    } else {
      print("Chat Room ID is invalid");
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
        title: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userMap!['uid'])
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column(
                children: [
                  Text(
                    widget.userMap!['name'],
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  Text(snapshot.data!['status'],
                      style:
                          const TextStyle(color: Colors.white, fontSize: 15)),
                ],
              );
            } else {
              return const SizedBox();
            }
          },
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
          IconButton(
            icon: const Icon(
              Icons.video_call,
              color: Colors.white,
            ),
            onPressed: () {
              // Handle video call action
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.phone,
              color: Colors.white,
            ),
            onPressed: () {
              // Handle phone call action
            },
          ),
          const SizedBox(width: 10), // Add some space at the end if needed
        ],
      ),
      body: widget.chatRoomId != null && widget.chatRoomId!.isNotEmpty
          ? Container(
              color: Colors.grey[100],
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: firebaseFirestore
                          .collection('chatroom')
                          .doc(widget.chatRoomId)
                          .collection('chats')
                          .orderBy('time', descending: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          print("Messages retrieved: ${snapshot.data!.docs}");
                          return ListView.builder(
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              DocumentSnapshot documentSnapshot =
                                  snapshot.data!.docs[index];
                              String messageId = documentSnapshot.id;
                              Map<String, dynamic> messageInfo =
                                  documentSnapshot.data()
                                      as Map<String, dynamic>;
                              return messageTile(
                                  size, messageInfo, messageId, context);
                            },
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text("Error: ${snapshot.error}"),
                          );
                        } else {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 8.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.attach_file,
                              color: Colors.deepPurple),
                          onPressed: () {
                            getImage();
                          },
                        ),
                        Expanded(
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
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
                          icon:
                              const Icon(Icons.send, color: Colors.deepPurple),
                          onPressed: onSendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : const Center(child: Text("Invalid Chat Room ID")),
    );
  }

  Widget messageTile(Size size, Map<String, dynamic> messageInfo,
      String messageId, BuildContext context) {
    bool isMe = messageInfo['sendby'] == firebaseAuth.currentUser?.displayName;
    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete'),
                  onTap: () {
                    deleteMessage(context, widget.chatRoomId, messageId);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
                        content: Text("Message Deleted"),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
      child: messageInfo['type'] == 'text'
          ? Container(
              padding: EdgeInsets.only(
                left: isMe ? size.width * 0.25 : 8.0,
                right: isMe ? 8.0 : size.width * 0.25,
                top: 8.0,
                bottom: 8.0,
              ),
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
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
                      messageInfo['message'],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      messageInfo['time'] != null
                          ? DateFormat('hh:mm a')
                              .format(messageInfo['time'].toDate())
                          : '',
                      textAlign: isMe ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              height: size.height / 2.5,
              width: size.width,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ShowImage(imageUrl: messageInfo['message'])));
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(border: Border.all()),
                      alignment: messageInfo['message'] != ""
                          ? null
                          : Alignment.center,
                      height: size.height / 2.5,
                      width: size.width / 2,
                      child: messageInfo['message'] != null &&
                              messageInfo['message'].isNotEmpty
                          ? Image.network(
                              fit: BoxFit.cover, messageInfo['message'])
                          : const Center(child: CircularProgressIndicator()),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Text(
                        messageInfo['time'] != null
                            ? DateFormat('hh:mm a')
                                .format(messageInfo['time'].toDate())
                            : '',
                        textAlign: isMe ? TextAlign.right : TextAlign.left,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> deleteMessage(
      BuildContext context, String? chatRoomId, String messageId) async {
    try {
      await firebaseFirestore
          .collection('chatroom')
          .doc(chatRoomId)
          .collection('chats')
          .doc(messageId)
          .delete();
      print('Message deleted');
    } catch (e) {
      print('Error deleting message: $e');
    }
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
