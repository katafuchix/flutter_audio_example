import 'package:flutter/material.dart';

//import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({Key? key}) : super(key: key);

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const platform = MethodChannel('com.example.audio/mode');
  bool _isSpeakerMode = false;

  Future<void> playAudio(String url) async {
    try {
      await platform.invokeMethod('playAudio', {'url': url});
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> stopAudio() async {
    try {
      await platform.invokeMethod('stopAudio');
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> setSpeakerMode(bool speakerMode) async {
    try {
      await platform.invokeMethod('setSpeakerMode', {'speaker': speakerMode});
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const audioUrl = 'https://deskplate.net/debug/b.mp3';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Player'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => playAudio(audioUrl),
              child: const Text('Play Audio'),
            ),
            ElevatedButton(
              onPressed: stopAudio,
              child: const Text('Stop Audio'),
            ),
            ElevatedButton(
              onPressed: () => setSpeakerMode(true),
              child: const Text('Switch to Speaker Mode'),
            ),
            ElevatedButton(
              onPressed: () => setSpeakerMode(false),
              child: const Text('Switch to Earpiece Mode'),
            ),
          ],
        ),
      ),
    );
  }
}
