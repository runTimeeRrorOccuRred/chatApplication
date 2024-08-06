import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:talk_application/view/createGroup.dart';

class AddMembers extends StatefulWidget {
  const AddMembers({super.key});

  @override
  State<AddMembers> createState() => _AddMembersState();
}

class _AddMembersState extends State<AddMembers> {
  TextEditingController searchController = TextEditingController();
  Map<String, dynamic>? userMap;
  bool isLoading = false;
  bool userFound = true;

  @override
  void initState() {
    super.initState();
    getCurrentUserAsAdmin();
  }

  getCurrentUserAsAdmin() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((map) {
      setState(() {
        membersList.add({
          "name": map['name'],
          "email": map['email'],
          'uid': map['uid'],
          'isAdmin': true
        });
      });
    });
  }

  addUserBYSearch() async {
    bool alreadyExist = false;
    for (int i = 0; i < membersList.length; i++) {
      if (membersList[i]['uid'] == userMap!['uid']) {
        alreadyExist = true;
      }
    }
    if (userMap != null) {
      if (alreadyExist == false) {
        setState(() {
          membersList.add({
            'name': userMap!['name'],
            'email': userMap!['email'],
            'uid': userMap!['uid'],
            'isAdmin': false
          });
          userMap = null;
        });
      }
    }
  }

  removeMembers(int index) {
    if (membersList[index]['uid'] != FirebaseAuth.instance.currentUser!.uid) {
      setState(() {
        membersList.removeAt(index);
      });
    }
  }

  getMembersBySearch() async {
    setState(() {
      isLoading = true;
      userFound = true;
      userMap = null;
    });

    if (searchController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: searchController.text)
          .get()
          .then((map) {
        if (map.docs.isNotEmpty) {
          setState(() {
            userMap = map.docs[0].data();
            isLoading = false;
          });
        } else {
          setState(() {
            userFound = false;
            isLoading = false;
          });
        }
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> membersList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Members"),
      ),
      body: Column(
        children: [
          Flexible(
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: membersList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text('${membersList[index]['name']}'),
                      subtitle: Text('${membersList[index]['email']}'),
                      trailing: GestureDetector(
                          onTap: () {
                            print(index);
                            setState(() {
                              removeMembers(index);
                            });
                          },
                          child: const Icon(Icons.close)),
                    );
                  })),
          TextFormField(
            controller: searchController,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  getMembersBySearch();
                  searchController.clear();
                },
              ),
              hintText: "Search by email",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          isLoading
              ? const CircularProgressIndicator()
              : userMap != null
                  ? GestureDetector(
                      onTap: () {
                        addUserBYSearch();
                      },
                      child: ListTile(
                        title: Text(userMap!['name']),
                        subtitle: Text(userMap!['email']),
                      ),
                    )
                  : !userFound
                      ? const Text("No user found")
                      : const SizedBox()
        ],
      ),
      floatingActionButton: membersList.length >= 2
          ? FloatingActionButton(
              backgroundColor: Colors.deepPurple,
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CreateGroup(
                              memberList: membersList,
                            )));
              },
              child: const Icon(
                Icons.forward,
                color: Colors.white,
              ),
            )
          : const SizedBox(),
    );
  }
}
