import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:journal_app/models/audio_note.dart';

class AudioRecorderScreen extends StatefulWidget {
  final Function(AudioNote) onSave;

  const AudioRecorderScreen({super.key, required this.onSave});

  @override
  _AudioRecorderScreenState createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  FlutterSoundRecorder? _audioRecorder;
  bool _isRecording = false;
  bool _isPaused = false;
  String _filePath = '';
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _openAudioSession();
  }

  Future<void> _openAudioSession() async {
    await _audioRecorder!.openRecorder();
    await Permission.microphone.request();
  }

  @override
  void dispose() {
    _audioRecorder!.closeRecorder();
    _audioRecorder = null;
    _titleController.dispose();
    super.dispose();
  }

  Future<String> _getFilePath() async {
    Directory tempDir = await getTemporaryDirectory();
    String path = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
    return path;
  }

  void _startOrResumeRecording() async {
    if (_isPaused) {
      await _audioRecorder!.resumeRecorder();
    } else {
      _filePath = await _getFilePath();
      await _audioRecorder!.startRecorder(
        toFile: _filePath,
        codec: Codec.aacMP4,
      );
    }
    setState(() {
      _isRecording = true;
      _isPaused = false;
    });
  }

  void _pauseRecording() async {
    await _audioRecorder!.pauseRecorder();
    setState(() {
      _isPaused = true;
    });
  }

  void _stopRecording() async {
    await _audioRecorder!.stopRecorder();
    setState(() {
      _isRecording = false;
      _isPaused = false;
    });
  }

  void _saveRecording() {
    if (_titleController.text.trim().isNotEmpty) {
      widget.onSave(
        AudioNote(
          filePath: _filePath,
          title: _titleController.text.trim(),
        )
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Audio Title',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isRecording
                  ? 'Recording...'
                  : _isPaused
                  ? 'Paused'
                  : 'Recorder Stopped',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            if (_isRecording || _isPaused)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isRecording ? _pauseRecording : null,
                    child: const Text('Pause'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _stopRecording,
                    child: const Text('Stop'),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: _startOrResumeRecording,
                child: const Text('Start Recording'),
              ),
            const SizedBox(height: 20),
            if (!_isRecording && !_isPaused && _filePath.isNotEmpty)
              ElevatedButton(
                onPressed: _saveRecording,
                child: const Text('Save Recording'),
              ),
          ],
        ),
      ),
    );
  }
}
