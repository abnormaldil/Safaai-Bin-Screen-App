import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BinSelectionPage extends StatefulWidget {
  @override
  _BinSelectionPageState createState() => _BinSelectionPageState();
}

class _BinSelectionPageState extends State<BinSelectionPage> {
  String? _selectedBin;
  bool _isLoading = false;

  Future<void> _saveSelectedBin() async {
    if (_selectedBin == null) return;

    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedBin', _selectedBin!);
      Navigator.pushReplacementNamed(context, '/screensaver');
    } catch (error) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save selection. Try again.')),
      );
    }
  }

  Future<List<String>> _fetchBins() async {
    final bins = await FirebaseFirestore.instance.collection('bin').get();
    return bins.docs.map((doc) => doc.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Bin')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<String>>(
          future: _fetchBins(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error fetching bins'));
            }

            final bins = snapshot.data ?? [];
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<String>(
                  hint: Text('Select a Bin'),
                  value: _selectedBin,
                  items: bins.map((bin) {
                    return DropdownMenuItem<String>(
                      value: bin,
                      child: Text(bin),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedBin = value);
                  },
                ),
                SizedBox(height: 16),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _saveSelectedBin,
                        child: Text('Save Selection'),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}
