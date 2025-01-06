import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'login.dart';
import 'user.dart';
import 'processing.dart';
import 'screensaver.dart';
import 'inactivity_wrapper.dart';
import 'bin_selection.dart'; // Import the BinSelectionPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app in landscape mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyAgjDoLAlRI-dmsvGEIAIwjAbMcukznaHc",
      appId: "1:618311522744:web:cd6c9db96c9c6bebfc174d",
      messagingSenderId: "618311522744",
      projectId: "rit24safaai",
    ),
  );

  // Check if bin selection is already done
  final prefs = await SharedPreferences.getInstance();
  final selectedBin = prefs.getString('selectedBin');

  runApp(AdminApp(selectedBin: selectedBin));
}

class AdminApp extends StatelessWidget {
  final String? selectedBin;

  AdminApp({required this.selectedBin});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safaai',
      debugShowCheckedModeBanner: false,
      initialRoute: selectedBin == null ? '/binSelection' : '/screensaver',
      routes: {
        '/binSelection': (context) => BinSelectionPage(),
        '/login': (context) => InactivityWrapper(
              child: LoginPage(),
            ),
        '/screensaver': (context) => Screensaver(),
        '/user': (context) => UserPage(),
        '/home': (context) => Home(),
        '/processing': (context)  => ProcessingPage(),
      },
    );
  }
}
