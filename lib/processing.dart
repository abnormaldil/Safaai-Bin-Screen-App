import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safaaibin/nonplastic.dart';
import 'package:safaaibin/plastic.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProcessingPage extends StatefulWidget {
  const ProcessingPage({super.key});

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _cancelProcessing() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final selectedBin = prefs.getString('selectedBin');
      if (selectedBin != null) {
        await FirebaseFirestore.instance
            .collection('bin')
            .doc(selectedBin)
            .update({'flag': 0});

        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 28, 162, 109),
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: _getFlagStream(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                final flag = snapshot.data!['flag'];
                if (flag == 2) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      final prefs = await SharedPreferences.getInstance();
                      final selectedBin = prefs.getString('selectedBin');
                      if (selectedBin != null) {
                        final docRef = FirebaseFirestore.instance
                            .collection('bin')
                            .doc(selectedBin);
                        await docRef.update({'flag': 0});
                        await docRef
                            .update({'plastic': FieldValue.increment(1)});
                      }
                    }
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const Plastic()),
                    );
                  });
                }

                if (flag == 3) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      final prefs = await SharedPreferences.getInstance();
                      final selectedBin = prefs.getString('selectedBin');
                      if (selectedBin != null) {
                        final docRef = FirebaseFirestore.instance
                            .collection('bin')
                            .doc(selectedBin);

                        await docRef.update({'flag': 0});

                        final email = user.email;
                        if (email != null) {
                          final userDocRef = FirebaseFirestore.instance
                              .collection('users')
                              .doc(email);

                          await userDocRef.update({
                            'CreditBalance': FieldValue.increment(-30),
                          });
                        }
                      }
                    }

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => NonPlastic()),
                    );
                  });
                }
              }
              return const SizedBox.shrink();
            },
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              padding: const EdgeInsets.all(30),
              constraints: const BoxConstraints(
                maxWidth: 400,
                maxHeight: 400,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeController,
                    child: const Text(
                      'Put The Plastic In',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Gilroy',
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Center(
                    child: Lottie.asset(
                      'assets/binopen.json',
                      width: 217,
                      height: 217,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: _cancelProcessing,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 226, 12, 30),
                      Color.fromARGB(255, 229, 40, 56),
                      Color.fromARGB(255, 228, 5, 5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Gilroy',
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<DocumentSnapshot> _getFlagStream() async* {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final selectedBin = prefs.getString('selectedBin');
      if (selectedBin != null) {
        yield* FirebaseFirestore.instance
            .collection('bin')
            .doc(selectedBin)
            .snapshots();
      }
    }
  }
}
