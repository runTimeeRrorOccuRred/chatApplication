import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:talk_application/chat/chatroom.dart';
import 'package:talk_application/contant/methods.dart';
import 'package:talk_application/view/grouppage.dart';
import 'package:talk_application/view/loginpage.dart';

class HomeScreen extends StatefulWidget {
  final String? userName;
  HomeScreen({this.userName, Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late Stream<QuerySnapshot> userStream;
  final TextEditingController searchController = TextEditingController();
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = firebaseAuth.currentUser;
    userStream = FirebaseFirestore.instance.collection('users').snapshots();
    WidgetsBinding.instance.addObserver(this);
    setStatus("Online");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      setStatus("Online");
    } else {
      setStatus("Offline");
    }
  }

  void setStatus(String status) async {
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({"status": status});
    }
  }

  void onSearch() {
    setState(() {
      if (searchController.text.isEmpty) {
        userStream = FirebaseFirestore.instance.collection('users').snapshots();
      } else {
        userStream = FirebaseFirestore.instance
            .collection('users')
            .where('name', isEqualTo: searchController.text)
            .snapshots();
      }
    });
  }

  String chatRoomId(String? user1, String user2) {
    if (user1 != null) {
      return user1.toLowerCase().codeUnits[0] > user2.toLowerCase().codeUnits[0]
          ? "$user1$user2"
          : "$user2$user1";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(color: Colors.white),
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
            child: IconButton(
              onPressed: () async {
                await logOut();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginPage()));
              },
              icon: const Icon(
                Icons.exit_to_app,
                color: Colors.white,
              ),
              tooltip: 'Log Out',
            ),
          )
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: searchController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: onSearch,
                  ),
                  prefixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            onSearch();
                          },
                        )
                      : null,
                  hintText: "Search by name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: userStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No Users Found"));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final user = snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          elevation: 3,
                          child: ListTile(
                            onTap: () async {
                              String roomId =
                                  chatRoomId(widget.userName, user['name']);
                              // Ensuring status update
                              // Adding delay before navigation
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatRoom(
                                    userMap: user,
                                    chatRoomId: roomId,
                                  ),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Text(
                                user['name'][0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              user['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(user['email']),
                            trailing: user['status'] == "Online"
                                ? const CircleAvatar(
                                    radius: 5,
                                    backgroundColor: Colors.green,
                                  )
                                : const SizedBox(),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const GroupPage()));
        },
        child: const Icon(
          Icons.group,
          color: Colors.white,
        ),
      ),
    );
  }
}
