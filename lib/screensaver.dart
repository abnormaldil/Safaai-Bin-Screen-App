import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:web_socket_channel/io.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Screensaver extends StatefulWidget {
  @override
  _ScreensaverState createState() => _ScreensaverState();
}

class _ScreensaverState extends State<Screensaver> {
  late VideoPlayerController _videoController;
  IOWebSocketChannel? _channel; // Nullable WebSocket channel
  bool _isLoggingIn = false; // Prevent multiple login attempts
  String? _errorMessage; // Store error messages

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _connectToWebSocket();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/screensaver.mp4')
      ..initialize().then((_) {
        setState(() {
          _videoController.play();
          _videoController.setLooping(true);
        });
      }).catchError((error) {
        print("Error initializing video: $error");
      });
  }

  Future<void> _connectToWebSocket() async {
    try {
      // Get selected bin ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? selectedBin = prefs.getString('selectedBin');

      if (selectedBin == null) {
        setState(() => _errorMessage = "No bin selected.");
        return;
      }

      // Fetch IP address from Firestore using the selected bin
      DocumentSnapshot binDoc = await FirebaseFirestore.instance
          .collection('bin')
          .doc(selectedBin)
          .get();

      if (!binDoc.exists || !binDoc.data().toString().contains('ip')) {
        setState(() => _errorMessage = "No IP found for selected bin.");
        return;
      }

      String ipAddress = binDoc['ip']; // Retrieve IP from Firestore

      // Connect WebSocket dynamically using retrieved IP
      _channel = IOWebSocketChannel.connect('ws://$ipAddress:81');
      print("WebSocket Connected to $ipAddress");

      _channel!.stream.listen((message) {
        print("Received NFC Data: $message");
        try {
          final data = jsonDecode(message);
          String email = data['email'];
          String password = data['password'];
          _loginAndExitScreensaver(email, password);
        } catch (e) {
          print("Error parsing NFC Data: $e");
          setState(() => _errorMessage = "Invalid NFC Data");
        }
      }, onError: (error) {
        print("WebSocket Error: $error");
        setState(() => _errorMessage = "WebSocket Connection Error");
      });
    } catch (e) {
      print("WebSocket Connection Failed: $e");
      setState(() => _errorMessage = "WebSocket Connection Failed");
    }
  }

  void _loginAndExitScreensaver(String email, String password) async {
    if (_isLoggingIn) return; // Avoid multiple login attempts
    _isLoggingIn = true;

    FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print("Login successful! Navigating to /user");

          // Allow time for pop before navigating
          Future.delayed(Duration(milliseconds: 200), () {
            Navigator.pushReplacementNamed(context, '/user',
                arguments: userCredential.user);
          });
        });
      }
    } catch (e) {
      print("Login Failed: $e");
    } finally {
      _isLoggingIn = false;
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _channel?.sink.close(); // Close WebSocket if connected
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/login'); // Manually exit screensaver
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToHome, // Tap exits screensaver manually
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: Stack(
          children: [
            if (_videoController.value.isInitialized)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              )
            else
              Center(child: CircularProgressIndicator()), // Show loading if video isn't ready
            if (_errorMessage != null)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
