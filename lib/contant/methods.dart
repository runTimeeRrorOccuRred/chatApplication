import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<User?> createAccount(String name, String email, String password) async {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  try {
    UserCredential userCredential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;
    if (user != null) {
      await user.updateProfile(displayName: name);
      print("Account creation successful for user: ${user.uid}");

      // Save additional user data to Firestore
      await firebaseFirestore.collection('users').doc(user.uid).set({
        "name": name,
        "email": email,
        "status": "",
        "uid": user.uid,
      });

      return user;
    } else {
      print("Account creation failed: User is null");
      return null;
    }
  } catch (e) {
    print("Error during account creation: $e");
    return null;
  }
}

Future<User?> login(String email, String password) async {
  FirebaseAuth auth = FirebaseAuth.instance;

  try {
    User? user = (await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    ))
        .user;

    if (user != null) {
      return user;
    } else {
      print("Login failed: User is null");
      return null;
    }
  } catch (e) {
    print("Error during login: $e");
    return null;
  }
}

Future<void> logOut() async {
  FirebaseAuth auth = FirebaseAuth.instance;

  try {
    await auth.signOut();
    print("Logout successful");
  } catch (e) {
    print("Error during logout: $e");
  }
}
