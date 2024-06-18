import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(VoiceAssistantApp());

class VoiceAssistantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Assistant',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false, // Hide debug banner
      home: VoiceAssistantHomePage(),
    );
  }
}

class VoiceAssistantHomePage extends StatefulWidget {
  @override
  _VoiceAssistantHomePageState createState() => _VoiceAssistantHomePageState();
}

class _VoiceAssistantHomePageState extends State<VoiceAssistantHomePage> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _text = "Press the button and start speaking";
  String _answer = ""; // New variable to hold the answer
  final String _apiKey = 'AIzaSyC1wk3gwXfOzQY4LOzJ7Nuw5RZOnYGqutg';
  final String _searchEngineId = '44099828af74f495b';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
          onResult: (val) => setState(() {
                _text = val.recognizedWords;
                _fetchAndReadData(_text);
              }));
    }
  }

  void _stopListening() async {
    setState(() => _isListening = false);
    _speech.stop();
  }

  Future<void> _fetchAndReadData(String query) async {
    try {
      final response = await http.get(Uri.parse(
          'https://www.googleapis.com/customsearch/v1?key=$_apiKey&cx=$_searchEngineId&q=$query'));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          _answer = data['items'][0]['snippet']; // Extract answer
          _text = query; // Set question as text (optional)
          _speak(_answer); // Speak the answer
        } else {
          _speak('Sorry, I found no results.');
        }
      } else {
        print('Failed to load data: ${response.statusCode}');
        _speak('Failed to fetch data. Please try again later.');
      }
    } catch (e) {
      print('Error fetching data: $e');
      _speak('Failed to fetch data. Please try again later.');
    }
    setState(() {}); // Trigger UI update
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Assistant'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: Text(
                  _text,
                  style: TextStyle(
                    fontSize: 24.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Text(
            'ANSWER:',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              _answer,
              style: TextStyle(fontSize: 20.0),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 60.0),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isListening ? _stopListening : _startListening,
        tooltip: 'Listen',
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
