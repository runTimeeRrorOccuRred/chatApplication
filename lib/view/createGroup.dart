import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:talk_application/view/homepage.dart';
import 'package:uuid/uuid.dart';

class CreateGroup extends StatefulWidget {
  final List<Map<String, dynamic>> memberList;
  const CreateGroup({required this.memberList, super.key});

  @override
  State<CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  bool isLoading = false;
  FirebaseAuth auth = FirebaseAuth.instance;
  void createGroup() async {
    setState(() {
      isLoading = true;
    });
    String groupId = const Uuid().v1();
    await FirebaseFirestore.instance.collection('groups').doc(groupId).set({
      'members': widget.memberList,
      'id': groupId,
      "name": groupNameController.text
    });

    for (int i = 0; i < widget.memberList.length; i++) {
      String uid = widget.memberList[i]['uid'];
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('groups')
          .doc(groupId)
          .set({'name': groupNameController.text, 'id': groupId});
    }
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('chats')
        .add({
      "message":
          "${FirebaseAuth.instance.currentUser!.displayName} created this group.",
      "type": "notify",
      "time": FieldValue.serverTimestamp(),
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false);
  }

  TextEditingController groupNameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Group"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: groupNameController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      hintText: "Enter group name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      createGroup();
                      // Handle create group action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Create Group",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
