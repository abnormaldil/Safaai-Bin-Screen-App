import 'package:flutter/material.dart';

class ProcessingPage extends StatefulWidget {
  const ProcessingPage({super.key});

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  bool _isProcessing = false;
  String _processingMessage = "Waiting for action...";

  Future<void> _startProcessing() async {
    setState(() {
      _isProcessing = true;
      _processingMessage = "Processing...";
    });

    try {
      // Simulate a long-running task (e.g., network request, data processing)
      await Future.delayed(const Duration(seconds: 3));

      // Simulate success or failure based on a random number
      if (DateTime.now().millisecond % 2 == 0) {
        setState(() {
          _processingMessage = "Processing Complete!";
        });
      } else {
        throw Exception("Simulated processing error.");
      }

    } catch (e) {
      setState(() {
        _processingMessage = "Error: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_isProcessing) const CircularProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _processingMessage,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center, // Center the text
              ),
            ),
            ElevatedButton(
              onPressed: _isProcessing ? null : _startProcessing, // Disable button while processing
              child: const Text('Start Processing'),
            ),
          ],
        ),
      ),
    );
  }
}