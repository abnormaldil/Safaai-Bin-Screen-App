import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode(); // Autofocus for email field
  IOWebSocketChannel? _channel;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();

    // Delay autofocus slightly to allow Flutter to finish rendering
    Future.delayed(Duration(milliseconds: 300), () {
      FocusScope.of(context).requestFocus(_emailFocusNode);
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
          _login(email, password);
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

  Future<void> _login(String email, String password) async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        Navigator.pushReplacementNamed(context, '/user',
            arguments: userCredential.user);
      } on FirebaseAuthException catch (e) {
        setState(() => _errorMessage = e.message);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _emailFocusNode.dispose(); // Dispose focus node
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Colors.transparent,
        elevation: 1,
        title: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          SizedBox(width: 175),
          Text(
            "Login",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Gilroy',
              color: Colors.white,
            ),
          ),
        ]),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email Field with Autofocus
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              value != null && value.contains('@')
                                  ? null
                                  : 'Enter a valid email',
                        ),
                        SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          obscureText: true,
                          validator: (value) =>
                              value != null && value.length >= 6
                                  ? null
                                  : 'Password must be at least 6 characters',
                        ),
                        SizedBox(height: 14),

                        // Error Message Display
                        if (_errorMessage != null)
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                        SizedBox(height: 14),

                        // Login Button with Gradient & Rounded Corners
                        _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white))
                            : GestureDetector(
                                onTap: () {
                                  if (_formKey.currentState!.validate()) {
                                    _login(_emailController.text,
                                        _passwordController.text);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color.fromARGB(255, 37, 232, 154),
                                        Color.fromARGB(255, 42, 254, 169),
                                        Color.fromARGB(255, 29, 213, 140),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.blueAccent.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(flex: 1, child: Container()), // Empty right-side space
        ],
      ),
    );
  }
}
