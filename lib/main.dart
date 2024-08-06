import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:talk_application/auth/authenticate.dart';
import 'package:talk_application/view/loginpage.dart';

//import 'loginpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyAMmDkVHFh8uhL_GIbo73_eUFxCjHFRV5Y",
            appId: "1:1093740561307:android:099365392b6a532eab573e",
            messagingSenderId: "1093740561307",
            projectId: "convo-app-d6ef2",
            storageBucket: "convo-app-d6ef2.appspot.com"));
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Authenticate(),
    );
  }
}
