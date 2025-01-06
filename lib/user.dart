import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _binName;
  int? _binDescription; // Store bin description as int (garbage level)
  String? _userName; // Store user name
  int? _creditBalance; // Store credit balance
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchBinDetails();
  }

  // Fetch the user's data from Firestore
  void _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Listen for real-time updates to the user's document
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.email) // Email is the document ID
            .snapshots()
            .listen((userDoc) {
          if (userDoc.exists) {
            setState(() {
              _userName = userDoc['Name']; // Store the Name field
              _creditBalance =
                  userDoc['CreditBalance'] as int?; // Store Credit Balance
              _isLoading = false;
            });
          } else {
            setState(() {
              _userName = "No name found"; // Default message
              _creditBalance = 0; // Default Credit Balance
              _isLoading = false;
            });
          }
        });
      } catch (e) {
        print('Error fetching user data: $e');
        setState(() {
          _userName = "Error fetching name"; // In case of error
          _creditBalance = 0;
          _isLoading = false;
        });
      }
    }
  }

  // Fetch the selected bin details (garbage level)
  void _fetchBinDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedBin = prefs.getString('selectedBin');

    if (selectedBin != null) {
      setState(() {
        _binName = selectedBin;
        _isLoading = true;
      });

      // Listen for real-time updates to the bin document
      _getBinDescription(selectedBin);
    } else {
      setState(() {
        _binDescription = null;
        _isLoading = false;
      });
    }
  }

  // Fetch bin description (garbage level) from Firestore
  void _getBinDescription(String binName) {
    FirebaseFirestore.instance
        .collection('bin')
        .doc(binName)
        .snapshots()
        .listen((binDoc) {
      if (binDoc.exists) {
        setState(() {
          _binDescription =
              binDoc['description'] as int?; // Description as garbage level
          _isLoading = false; // End loading state once data is fetched
        });
      } else {
        setState(() {
          _binDescription = null; // No data found
          _isLoading = false;
        });
      }
    });
  }

  // Handle "Add Plastic" action
  void _addPlastic() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Get the selected bin name from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final selectedBin = prefs.getString('selectedBin');

        if (selectedBin != null) {
          // Update the 'flag' field in the specific bin document (e.g., bin1, bin2, etc.)
          await FirebaseFirestore.instance
              .collection('bin')
              .doc(selectedBin) // Use the selected bin (bin1, bin2, etc.)
              .update({
            'flag': 1, // Set flag to 1 indicating the processing state
          });

          // Ensure that the update was successful by logging
          print("Flag successfully updated for bin: $selectedBin");

          // Navigate to the Processing Page
          Navigator.pushReplacementNamed(context, '/processing');
        } else {
          print("No bin selected.");
        }
      } catch (e) {
        print("Error updating flag: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = ModalRoute.of(context)!.settings.arguments as User?;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.transparent, // Transparent background
        elevation: 0, // No shadow
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Align left and right
          children: [
            // Left side: "Safaai"
            Text(
              "Safaai",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Gilroy',
                color: const Color.fromARGB(255, 80, 79, 79), // White text
              ),
            ),
            // Right side: Column with "Hello," and username
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end, // Align text to the right
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Hola,",
                  style: TextStyle(
                    fontSize: 24,
                    color: const Color.fromARGB(
                        255, 80, 79, 79), // Dark text color
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  '${_userName ?? "User"}!', // Username or default "User"
                  style: TextStyle(
                    fontSize: 26,
                    color: const Color.fromARGB(
                        255, 80, 79, 79), // Dark text color
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          alignment: Alignment.center,
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(255, 25, 255, 182)
                                    .withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 25,
                                offset: Offset(0, 3),
                              ),
                            ],
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.fromARGB(255, 29, 213, 140),
                                Color.fromARGB(255, 42, 254, 169),
                                Color.fromARGB(255, 29, 213, 140),
                              ],
                            ),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  FontAwesomeIcons.leaf,
                                  size: 54.0, // Adjust the size as needed
                                  color: Color.fromARGB(255, 255, 255, 255),
                                ),
                                Text(
                                  '${_creditBalance ?? 0}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 54,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Gilroy',
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        SfRadialGauge(
                          axes: <RadialAxis>[
                            RadialAxis(
                              minimum: 0,
                              maximum: 100,
                              showLabels: false,
                              showTicks: false,
                              axisLineStyle: AxisLineStyle(
                                thickness: 0.3,
                                cornerStyle: CornerStyle.bothCurve,
                                color: const Color.fromARGB(255, 220, 220, 220),
                                thicknessUnit: GaugeSizeUnit.factor,
                              ),
                              pointers: <GaugePointer>[
                                RangePointer(
                                  value: _binDescription?.toDouble() ??
                                      0.0, // Current value
                                  cornerStyle: CornerStyle.bothCurve,
                                  width: 0.3, // Pointer width
                                  sizeUnit: GaugeSizeUnit.factor,
                                  gradient: SweepGradient(
                                    colors: [
                                      Color.fromARGB(255, 23, 137, 91),
                                      Color.fromARGB(255, 32, 195, 130),
                                      Color.fromARGB(255, 24, 249, 159),
                                    ],
                                  ),
                                  enableAnimation: true, // Enable animation
                                  animationType:
                                      AnimationType.ease, // Animation type
                                  animationDuration:
                                      1000, 
                                ),
                              ],
                              annotations: <GaugeAnnotation>[
                                GaugeAnnotation(
                                  positionFactor: 0.15,
                                  angle: 90,
                                  widget: TweenAnimationBuilder<double>(
                                    duration: Duration(
                                        milliseconds:
                                            500), 
                                    tween: Tween<double>(
                                      begin: 0,
                                      end: _binDescription?.toDouble() ?? 0.0,
                                    ), // Transitioning value
                                    builder: (BuildContext context,
                                        double value, Widget? child) {
                                      return Text(
                                        "${value.toStringAsFixed(0)}%", // Smoothly transitioning value
                                        style: TextStyle(
                                          fontSize: 54,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Gilroy',
                                          color:
                                              Color.fromARGB(255, 36, 224, 149),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Right Column (Message and Button)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Please put plastic",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        // Bottom row: "Add Plastic" Button
                        GestureDetector(
                          onTap: () => _addPlastic,
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 100, vertical: 10),
                            padding: EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 45), // Adjust padding for height
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(30), // Rounded corners
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 37, 232, 154),
                                  Color.fromARGB(255, 42, 254, 169),
                                  Color.fromARGB(255, 29, 213, 140),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromARGB(255, 42, 254, 169)
                                      .withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 5,
                                  offset: Offset(0, 3), // Shadow positioning
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Dispose Plastic',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Gilroy',
                                  color: const Color.fromARGB(
                                      255, 255, 255, 255), // Black text
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
