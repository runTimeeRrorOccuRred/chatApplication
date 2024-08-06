import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:talk_application/view/homepage.dart';
import 'package:talk_application/view/loginpage.dart';

// ignore: must_be_immutable
class Authenticate extends StatelessWidget {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  Authenticate({super.key});

  @override
  Widget build(BuildContext context) {
    return (firebaseAuth.currentUser != null)
        ? HomeScreen(
            userName: firebaseAuth.currentUser!.displayName,
          )
        : const LoginPage();
  }
}
