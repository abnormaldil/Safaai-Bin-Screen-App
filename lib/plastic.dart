import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'processing.dart';
import 'package:lottie/lottie.dart';
import 'user.dart';

class Plastic extends StatefulWidget {
  const Plastic({super.key});

  @override
  State<Plastic> createState() => _PlasticState();
}

class _PlasticState extends State<Plastic> {
  int plasticCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPlasticCount();
  }

  Future<void> _fetchPlasticCount() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final selectedBin = prefs.getString('selectedBin');
      if (selectedBin != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('bin')
            .doc(selectedBin)
            .get();
        setState(() {
          plasticCount = doc['plastic'] ?? 0;
        });
      }
    }
  }

  Future<void> _resetFlagAndGoBack() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final selectedBin = prefs.getString('selectedBin');
      if (selectedBin != null) {
        await FirebaseFirestore.instance
            .collection('bin')
            .doc(selectedBin)
            .update({'flag': 1});
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ProcessingPage()),
        );
      }
    }
  }

  Future<void> _finishDepositingPlastic() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final selectedBin = prefs.getString('selectedBin');
      if (selectedBin != null) {
        final email = user.email;
        if (email != null) {
          DocumentSnapshot binDoc = await FirebaseFirestore.instance
              .collection('bin')
              .doc(selectedBin)
              .get();

          int plasticCount = binDoc['plastic'] ?? 0;
          int creditIncrement = plasticCount * 10;

          // Fetch current totalplastic value from user's document
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(email)
              .get();

          int currentTotalPlastic = userDoc['totalplastic'] ?? 0;
          int newTotalPlastic = currentTotalPlastic + plasticCount;

          // Update both CreditBalance and totalplastic
          await FirebaseFirestore.instance
              .collection('users')
              .doc(email)
              .update({
            'CreditBalance': FieldValue.increment(creditIncrement),
            'totalplastic': newTotalPlastic,
          });

          // Reset plastic count and flag in the bin document
          await FirebaseFirestore.instance
              .collection('bin')
              .doc(selectedBin)
              .update({
            'plastic': 0,
            'flag': 0,
          });

          // Show overlay notification
          final overlay = Overlay.of(context);
          final overlayEntry = OverlayEntry(
            builder: (context) => Positioned(
              top: 20,
              left: MediaQuery.of(context).size.width * 0.35,
              child: Material(
                color: Colors.transparent,
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(seconds: 2),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.3,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 36, 213, 142),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$plasticCount Deposited and Earned $creditIncrement SaFi!',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Gilroy',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          Navigator.of(context)
              .pop(MaterialPageRoute(builder: (context) => UserPage()));

          overlay?.insert(overlayEntry);
          await Future.delayed(const Duration(seconds: 4));
          overlayEntry.remove();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 2, 83, 51),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: Lottie.asset(
                'assets/plastic.json',
                width: 500,
                height: 500,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Plastic Deposited:',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Gilroy',
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '$plasticCount',
                  style: const TextStyle(
                    fontSize: 150,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilroy',
                    shadows: [
                      Shadow(
                        offset: Offset(5, 5),
                        blurRadius: 0,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _resetFlagAndGoBack,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 12, 152, 245),
                              Color.fromARGB(255, 54, 165, 255),
                              Color.fromARGB(255, 30, 146, 241),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(15),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                    const SizedBox(width: 50),
                    GestureDetector(
                      onTap: _finishDepositingPlastic,
                      child: Container(
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
                          // boxShadow: [
                          //   BoxShadow(
                          //     color: Color.fromARGB(255, 42, 254, 169)
                          //         .withOpacity(0.3),
                          //     blurRadius: 10,
                          //     spreadRadius: 5,
                          //     offset: Offset(0, 3),
                          //   ),
                          // ],
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(15),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
