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
  static const MethodChannel _channel = MethodChannel('speaker_control');
  bool _isSpeakerOn = false;

  Future<void> _playNativeAudio() async {
    await _channel.invokeMethod('playAudioWithSpeaker', {
      'useSpeaker': _isSpeakerOn,
      'url': 'https://deskplate.net/debug/b.mp3',
    });
  }

  void _toggleSpeaker() async {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });

    // 🔽 Swift側に再生 + スピーカー状態を渡す
    await _channel.invokeMethod('playAudioWithSpeaker', {
      'useSpeaker': _isSpeakerOn,
      'url': 'https://deskplate.net/debug/b.mp3',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Audio + Speaker Toggle")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _playNativeAudio,
              child: const Text("▶️ 再生（ネイティブ）"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleSpeaker,
              child: Text(_isSpeakerOn ? "🔈 通常出力に切替" : "📢 スピーカー出力に切替"),
            ),
          ],
        ),
      ),
    );
  }
}

/*
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
*/
