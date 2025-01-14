import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:safaaibin/processing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _binName;
  int? _binDescription;
  String? _userName;
  int? _creditBalance;
  bool _isLoading = true;
  bool _isCreditBalanceVisible = true;
  AudioPlayer _player = AudioPlayer();
  double _dragOffset = 0.0;
  final double _maxDragDistance = 130.0;
  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchBinDetails();
  }

  void _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .snapshots()
          .listen((userDoc) {
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc['Name'];
            _creditBalance = userDoc['CreditBalance'] as int?;
            _isLoading = false;
          });
        } else {
          setState(() {
            _userName = "No name found";
            _creditBalance = 0;
            _isLoading = false;
          });
        }
      });
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      
      _dragOffset += details.delta.dy;
      if (_dragOffset < 0) _dragOffset = 0; 
      if (_dragOffset > _maxDragDistance) _dragOffset = _maxDragDistance;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset >= _maxDragDistance * 0.9) {
      
      _addPlastic();
    }
    setState(() {
      
      _dragOffset = 0;
    });
  }

  Future<void> _redeemCredits(BuildContext context, int creditBalance,
      Map<String, dynamic> userData) async {
    if (creditBalance >= 100) {
      int redeemedCredit =
          creditBalance - (creditBalance % 100); 
      int newCreditBalance = creditBalance % 100; 

      
      User? user = _auth.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.email)
              .update({'CreditBalance': newCreditBalance});

          
          Timestamp transactionTime = Timestamp.now();
          String upiId = userData['UpiId'];
          String email = userData['Email'];

          await FirebaseFirestore.instance
              .collection('transactions')
              .doc(user.email)
              .collection(user.email!)
              .add({
            'RedeemAmount': redeemedCredit,
            'Time': transactionTime,
            'Date': transactionTime.toDate(),
            'UpiId': upiId,
            'Email': email,
          });

          
          var assetSource = AssetSource('claimed.mp3');
          await _player.play(assetSource);
          final overlay = Overlay.of(context);
          final overlayEntry = OverlayEntry(
            builder: (context) => Positioned(
              top: 20, 
              left: MediaQuery.of(context).size.width *
                  0.4, 
              child: Material(
                color: Colors.transparent,
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(seconds: 2), 
                  child: Container(
                    width: MediaQuery.of(context).size.width *
                        0.15, 
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                          255, 36, 213, 142), 
                      borderRadius: BorderRadius.circular(20), 
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          color: Colors.white,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Claimed!",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Gilroy',
                              color: const Color.fromARGB(255, 255, 255, 255),
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

          
          overlay.insert(overlayEntry);

          
          await Future.delayed(Duration(seconds: 2));

          
          overlayEntry.remove();
        } catch (error) {
          print("Error saving transaction: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred. Please try again.'),
            ),
          );
        }
      }
    } else {
      
      var assetSource = AssetSource('error.mp3');
      await _player.play(assetSource);

      
      final overlay = Overlay.of(context);
      final overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: 20, 
          left: MediaQuery.of(context).size.width * 0.4, 
          child: Material(
            color: Colors.transparent,
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(seconds: 2), 
              child: Container(
                width: MediaQuery.of(context).size.width *
                    0.23, 
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red, 
                  borderRadius: BorderRadius.circular(20), 
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Invalid Redemption!",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Gilroy',
                          color: const Color.fromARGB(255, 255, 255, 255),
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

      
      overlay.insert(overlayEntry);

      
      await Future.delayed(Duration(seconds: 2));

      
      overlayEntry.remove();
    }
  }

  void _fetchBinDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedBin = prefs.getString('selectedBin');
    if (selectedBin != null) {
      setState(() {
        _binName = selectedBin;
        _isLoading = true;
      });
      _getBinDescription(selectedBin);
    } else {
      setState(() {
        _binDescription = null;
        _isLoading = false;
      });
    }
  }

  void _getBinDescription(String binName) {
    FirebaseFirestore.instance
        .collection('bin')
        .doc(binName)
        .snapshots()
        .listen((binDoc) {
      if (binDoc.exists) {
        setState(() {
          _binDescription = binDoc['description'] as int?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _binDescription = null;
          _isLoading = false;
        });
      }
    });
  }

  void _addPlastic() async {
    User? user = _auth.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final selectedBin = prefs.getString('selectedBin');
      if (selectedBin != null) {
        await FirebaseFirestore.instance
            .collection('bin')
            .doc(selectedBin)
            .update({'flag': 1});
        Navigator.of(context).push(_createFadeRoute(ProcessingPage()));
      }
    }
  }

  Route _createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration:
          Duration(milliseconds: 400), 
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Safaai",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Gilroy',
                color: const Color.fromARGB(255, 80, 79, 79),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Hola,",
                  style: TextStyle(
                    fontSize: 24,
                    color: const Color.fromARGB(255, 80, 79, 79),
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  '${_userName ?? "User"}!',
                  style: TextStyle(
                    fontSize: 26,
                    color: const Color.fromARGB(255, 80, 79, 79),
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
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  Flexible(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: screenWidth * 0.2,
                              height: screenHeight * 0.45,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 30, 30, 30),
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color.fromARGB(255, 207, 207, 207)
                                            .withOpacity(0.5),
                                    spreadRadius: 10,
                                    blurRadius: 15,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(10),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Flexible(
                                    flex: 2,
                                    child: SfRadialGauge(
                                      axes: <RadialAxis>[
                                        RadialAxis(
                                          minimum: 0,
                                          maximum: 100,
                                          showLabels: false,
                                          showTicks: false,
                                          axisLineStyle: AxisLineStyle(
                                            thickness: 0.3,
                                            cornerStyle: CornerStyle.bothCurve,
                                            color: const Color.fromARGB(
                                                255, 232, 231, 231)!,
                                            thicknessUnit: GaugeSizeUnit.factor,
                                          ),
                                          pointers: <GaugePointer>[
                                            RangePointer(
                                              value:
                                                  _binDescription?.toDouble() ??
                                                      0.0,
                                              cornerStyle:
                                                  CornerStyle.bothCurve,
                                              width: 0.3,
                                              sizeUnit: GaugeSizeUnit.factor,
                                              gradient: SweepGradient(
                                                colors: [
                                                  Color(0xFF17975B),
                                                  Color(0xFF20C382),
                                                  Color(0xFF18F99F),
                                                ],
                                              ),
                                              enableAnimation: true,
                                              animationType: AnimationType.ease,
                                              animationDuration: 1000,
                                            ),
                                          ],
                                          annotations: <GaugeAnnotation>[
                                            GaugeAnnotation(
                                              positionFactor: 0.90,
                                              angle: 90,
                                              widget: Column(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .start, 
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  TweenAnimationBuilder<int>(
                                                    tween: IntTween(
                                                        begin: 0,
                                                        end: _binDescription ??
                                                            0),
                                                    duration: Duration(
                                                        milliseconds: 500),
                                                    builder: (context, value,
                                                        child) {
                                                      return Text(
                                                        "$value%",
                                                        style: TextStyle(
                                                          fontSize: 30,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontFamily: 'Gilroy',
                                                          color: const Color
                                                              .fromARGB(255, 23,
                                                              228, 146),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  Text(
                                                    "Bin Filled",
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'Gilroy',
                                                      color:
                                                          const Color.fromARGB(
                                                              255,
                                                              255,
                                                              255,
                                                              255),
                                                      height: 0.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 35,
                            ),
                            Container(
                              width: screenWidth * 0.2,
                              height: screenHeight * 0.45,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 30, 30, 30),
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color.fromARGB(255, 207, 207, 207)
                                            .withOpacity(0.5),
                                    spreadRadius: 10,
                                    blurRadius: 15,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(10),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Flexible(
                                    flex: 2,
                                    child: SfRadialGauge(
                                      axes: <RadialAxis>[
                                        RadialAxis(
                                          minimum: 0,
                                          maximum: 100,
                                          showLabels: false,
                                          showTicks: false,
                                          axisLineStyle: AxisLineStyle(
                                            thickness: 0.3,
                                            cornerStyle: CornerStyle.bothCurve,
                                            color: const Color.fromARGB(
                                                255, 255, 255, 255)!,
                                            thicknessUnit: GaugeSizeUnit.factor,
                                          ),
                                          pointers: <GaugePointer>[
                                            RangePointer(
                                              value:
                                                  _binDescription?.toDouble() ??
                                                      0.0,
                                              cornerStyle:
                                                  CornerStyle.bothCurve,
                                              width: 0.3,
                                              sizeUnit: GaugeSizeUnit.factor,
                                              gradient: SweepGradient(
                                                colors: [
                                                  Color(0xFF17975B),
                                                  Color(0xFF20C382),
                                                  Color(0xFF18F99F),
                                                ],
                                              ),
                                              enableAnimation: true,
                                              animationType: AnimationType.ease,
                                              animationDuration: 1000,
                                            ),
                                          ],
                                          annotations: <GaugeAnnotation>[
                                            GaugeAnnotation(
                                              positionFactor: 0.90,
                                              angle: 90,
                                              widget: Column(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .start, 
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  TweenAnimationBuilder<int>(
                                                    tween: IntTween(
                                                        begin: 0,
                                                        end: _binDescription ??
                                                            0),
                                                    duration: Duration(
                                                        milliseconds: 500),
                                                    builder: (context, value,
                                                        child) {
                                                      return Text(
                                                        "$value%",
                                                        style: TextStyle(
                                                          fontSize: 30,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontFamily: 'Gilroy',
                                                          color: const Color
                                                              .fromARGB(255, 23,
                                                              228, 146),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  Text(
                                                    "Bin Filled",
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'Gilroy',
                                                      color:
                                                          const Color.fromARGB(
                                                              255,
                                                              255,
                                                              255,
                                                              255),
                                                      height: 0.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Container(
                              width: screenWidth * 0.2,
                              height: screenHeight * 0.22,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 30, 30, 30),
                                borderRadius: BorderRadius.circular(35),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color.fromARGB(255, 207, 207, 207)
                                            .withOpacity(0.5),
                                    spreadRadius: 10,
                                    blurRadius: 15,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TweenAnimationBuilder<int>(
                                    tween: IntTween(
                                        begin: 0, end: _binDescription ?? 0),
                                    duration: Duration(milliseconds: 800),
                                    builder: (context, value, child) {
                                      return Text(
                                        "$value",
                                        style: TextStyle(
                                          fontSize: 45,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Gilroy',
                                          color: const Color.fromARGB(
                                              255, 23, 228, 146),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Total\nDisposals",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Gilroy',
                                      color: const Color.fromARGB(
                                          255, 255, 255, 255),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 35,
                            ),
                            Container(
                              width: screenWidth * 0.2,
                              height: screenHeight * 0.22,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 30, 30, 30),
                                borderRadius: BorderRadius.circular(35),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color.fromARGB(255, 207, 207, 207)
                                            .withOpacity(0.5),
                                    spreadRadius: 10,
                                    blurRadius: 15,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TweenAnimationBuilder<int>(
                                    tween: IntTween(
                                        begin: 0, end: _binDescription ?? 0),
                                    duration: Duration(milliseconds: 800),
                                    builder: (context, value, child) {
                                      return Text(
                                        "$value",
                                        style: TextStyle(
                                          fontSize: 45,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Gilroy',
                                          color: const Color.fromARGB(
                                              255, 23, 228, 146),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Total\nEarnings",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Gilroy',
                                      color: const Color.fromARGB(
                                          255, 255, 255, 255),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 0,
                  ),
                  Flexible(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: screenWidth * 0.25,
                              height: screenHeight * 0.68,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 30, 30, 30),
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color.fromARGB(255, 207, 207, 207)
                                            .withOpacity(0.5),
                                    spreadRadius: 10,
                                    blurRadius: 15,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(10),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Flexible(
                                    flex: 2,
                                    child: Container(
                                      width: 170,
                                      height: 170,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
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
                                            color: const Color.fromARGB(
                                                    255, 42, 254, 169)
                                                .withOpacity(0.3),
                                            blurRadius: 15,
                                            spreadRadius: 5,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              FontAwesomeIcons.leaf,
                                              size: 35,
                                              color: Colors.white,
                                            ),
                                            TweenAnimationBuilder<int>(
                                              key: ValueKey<bool>(
                                                  _isCreditBalanceVisible),
                                              tween: IntTween(
                                                  begin: 0,
                                                  end: _creditBalance ?? 0),
                                              duration:
                                                  Duration(milliseconds: 500),
                                              builder: (context, value, child) {
                                                return Text(
                                                  _isCreditBalanceVisible
                                                      ? '$value'
                                                      : '---',
                                                  style: TextStyle(
                                                    fontSize: 45,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Gilroy',
                                                    color: const Color.fromARGB(
                                                        255, 255, 255, 255),
                                                  ),
                                                );
                                              },
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _isCreditBalanceVisible =
                                                      !_isCreditBalanceVisible;
                                                });
                                              },
                                              child: Icon(
                                                _isCreditBalanceVisible
                                                    ? FontAwesomeIcons.eyeSlash
                                                    : FontAwesomeIcons.eye,
                                                size: 20,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  GestureDetector(
                                    onTap: () {
                                      User? user = _auth
                                          .currentUser; 
                                      _redeemCredits(
                                          context, _creditBalance ?? 0, {
                                        'UpiId': user?.email ??
                                            '', 
                                        'Email': user?.email ?? '',
                                      });
                                    },
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 45, vertical: 10),
                                      padding: EdgeInsets.symmetric(
                                          vertical:
                                              10), 
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            30), 
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
                                            color: Color.fromARGB(
                                                    255, 42, 254, 169)
                                                .withOpacity(0.3),
                                            blurRadius: 10,
                                            spreadRadius: 5,
                                            offset: Offset(
                                                0, 3), 
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Redeem',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Gilroy',
                                            color: const Color.fromARGB(
                                                255, 255, 255, 255),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 35,
                            ),
                            Container(
                              width: screenWidth * 0.17,
                              height: screenHeight * 0.68,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 30, 30, 30),
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color.fromARGB(255, 207, 207, 207)
                                            .withOpacity(0.5),
                                    spreadRadius: 10,
                                    blurRadius: 15,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(10),
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  Positioned(
                                    top:
                                        _dragOffset, 
                                    child: GestureDetector(
                                      onVerticalDragUpdate:
                                          _onVerticalDragUpdate,
                                      onVerticalDragEnd: _onVerticalDragEnd,
                                      child: Container(
                                        width:
                                            130, 
                                        height: 130,
                                        decoration: BoxDecoration(
                                          shape: BoxShape
                                              .circle, 
                                          gradient: LinearGradient(
                                            colors: [
                                              Color.fromARGB(255, 37, 232, 154),
                                              Color.fromARGB(255, 42, 254, 169),
                                              Color.fromARGB(255, 29, 213, 140),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color.fromARGB(
                                                      255, 42, 254, 169)
                                                  .withOpacity(0.3),
                                              blurRadius: 10,
                                              spreadRadius: 5,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Lottie.asset(
                                            'assets/arrow.json',
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: _dragOffset +
                                        150, 
                                    child: Center(
                                      child: Text(
                                        'Dispose Plastic\nNow',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Gilroy',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                ],
              ),
      ),
    );
  }
}
