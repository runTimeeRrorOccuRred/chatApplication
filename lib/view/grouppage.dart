import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:talk_application/view/addMembers.dart';
import 'package:talk_application/view/groupchats.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  List groupList = [];
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getAvailableGroups();
  }

  void getAvailableGroups() async {
    String uid = firebaseAuth.currentUser!.uid;
    await firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('groups')
        .get()
        .then((map) {
      setState(() {
        isLoading = false;
        groupList = map.docs;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Page"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupList.isEmpty
              ? const Center(child: Text("No groups to show"))
              : ListView.builder(
                  itemCount: groupList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.group),
                      title: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupChats(
                                groupName: groupList[index]['name'],
                                groupId: groupList[index]['id'],
                              ),
                            ),
                          );
                        },
                        child: Text(groupList[index]['name']),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMembers()),
          );
        },
        child: const Icon(
          Icons.create,
          color: Colors.white,
        ),
      ),
    );
  }

  void showCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController groupNameController = TextEditingController();
        return AlertDialog(
          title: const Text('Create Group'),
          content: TextField(
            controller: groupNameController,
            decoration: const InputDecoration(
              hintText: 'Enter group name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                // Handle group creation logic here
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GroupPage()),
                ).then((value) {
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }
}
