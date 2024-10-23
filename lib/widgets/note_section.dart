import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'dart:async';  // Import for Timer
import '../models/audio_note.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

//import '../services/storage_service.dart';

class NoteSection extends StatefulWidget {
  final Color backgroundColor;
  final Function(String) onContentChanged;
  final String initialContent;
  final String initialDescription;
  final Function(String) onDescriptionChanged;
  final String categoryName;
  final List<AudioNote> audioNotes;
  final Function(AudioNote) onDeleteAudio;
  final Function(AudioNote) onAddAudio;

  const NoteSection({
    super.key,
    required this.backgroundColor,
    required this.onContentChanged,
    required this.initialContent,
    required this.initialDescription,
    required this.onDescriptionChanged,
    required this.categoryName,
    required this.audioNotes,
    required this.onDeleteAudio,
    required this.onAddAudio,
  });

  @override
  _NoteSectionState createState() => _NoteSectionState();
}

class _NoteSectionState extends State<NoteSection> {
  late quill.QuillController _controller;
  Timer? _autoSaveTimer;  // Declare a Timer for auto-saving
  String _currentContent = '';
  late TextEditingController _descriptionController;
  late TextEditingController _audioTitleController;

  FlutterSoundRecorder? _audioRecorder;
  FlutterSoundPlayer? _audioPlayer;
  bool _isRecording = false;
  bool _isPlaying = false;
  String _recordedFilePath = '';
  String? _currentlyPlayingAudio;

  @override
  void initState() {
    super.initState();
    _initializeQuillController();
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _audioTitleController = TextEditingController();
    _controller.addListener(_onContentChanged);
    _descriptionController.addListener(_onDescriptionChanged);
    _startAutoSaveTimer();  // Start the timer when the widget is initialized
    _audioPlayer = FlutterSoundPlayer();
    _audioRecorder = FlutterSoundRecorder();
    _initializeAudio();
  }

  // Initialize the QuillController with the initial content
  void _initializeQuillController() {
    if (widget.initialContent.isNotEmpty) {
      var myDocument = quill.Document.fromJson(jsonDecode(widget.initialContent));
      _controller = quill.QuillController(
        document: myDocument,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      _controller = quill.QuillController.basic();
    }
  }

  Future<void> _initializeAudio() async {
    await _audioRecorder!.openRecorder();
    await _audioPlayer!.openPlayer();
    await Permission.microphone.request();
  }

  void _onDescriptionChanged() {
    widget.onDescriptionChanged(_descriptionController.text);
  }

  // Function to handle content changes and save immediately
  void _onContentChanged() {
    var json = jsonEncode(_controller.document.toDelta().toJson());
    _currentContent = json;  // Update the current content
    widget.onContentChanged(json);  // Save immediately when content changes
  }

  // Function to start the auto-save timer
  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_currentContent.isNotEmpty) {
        widget.onContentChanged(_currentContent);  // Auto-save every 30 seconds
      }
    });
  }

  Future<String> _getFilePath() async {
    Directory tempDir = await getApplicationDocumentsDirectory();
    String path =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
    return path;
  }

  Future<void> _startRecording() async {
    if (await Permission.microphone.isGranted) {
      _recordedFilePath = await _getFilePath();
      await _audioRecorder!.startRecorder(
        toFile: _recordedFilePath,
        codec: Codec.aacMP4,
      );
      setState(() {
        _isRecording = true;
      });
    } else {
      await Permission.microphone.request();
    }
  }

  Future<void> _stopRecording() async {
    await _audioRecorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    _showSaveAudioDialog();
  }

  void _showSaveAudioDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Recording'),
          content: TextField(
            controller: _audioTitleController,
            decoration: const InputDecoration(
              labelText: 'Audio Title',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Cancel and delete the recording
                File(_recordedFilePath).deleteSync();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Save the recording
                if (_audioTitleController.text.trim().isNotEmpty) {
                  widget.onAddAudio(
                    AudioNote(
                      filePath: _recordedFilePath,
                      title: _audioTitleController.text.trim(),
                    ),
                  );
                }
                _audioTitleController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _playAudio(String filePath) async {
    if (_isPlaying && _currentlyPlayingAudio == filePath) {
      await _audioPlayer!.stopPlayer();
      setState(() {
        _isPlaying = false;
        _currentlyPlayingAudio = null;
      });
    } else {
      await _audioPlayer!.startPlayer(
        fromURI: filePath,
        codec: Codec.aacMP4,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _currentlyPlayingAudio = null;
          });
        },
      );
      setState(() {
        _isPlaying = true;
        _currentlyPlayingAudio = filePath;
      });
    }
  }

  @override
  void didUpdateWidget(NoteSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialContent != oldWidget.initialContent) {
      _controller.removeListener(_onContentChanged);
      _initializeQuillController();
      _controller.addListener(_onContentChanged);
      setState(() {});
    }
    if (widget.initialDescription != oldWidget.initialDescription) {
      _descriptionController.text = widget.initialDescription;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _descriptionController.dispose();
    _autoSaveTimer?.cancel();  // Cancel the auto-save timer when the widget is disposed
    _audioTitleController.dispose();
    _audioRecorder!.closeRecorder();
    _audioPlayer!.closePlayer(); // Close the audio player when disposed
    _audioPlayer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.lerp(widget.backgroundColor, Colors.white, 0.5),
      child: Column(
        children: [
          if (widget.categoryName == 'Journal' || widget.categoryName == 'Gefühle')
            quill.QuillToolbar.simple(
              controller: _controller,  // Use the simple toolbar
              configurations: quill.QuillSimpleToolbarConfigurations(
                  multiRowsDisplay: false,
                  showClipboardCopy: false,
                  showFontFamily: false,
                  showIndent: false,
                  showHeaderStyle: false,
                  showLink: false,
                  showQuote: false,
                  showClipboardCut: false,
                  showClipboardPaste: false,
                  showCodeBlock: false,
                  showInlineCode: false,
                  showStrikeThrough: false,
                  showSubscript: false,
                  showSuperscript: false,
                  color: Colors.grey[700],
                  buttonOptions: const quill.QuillSimpleToolbarButtonOptions(
                      undoHistory: quill.QuillToolbarHistoryButtonOptions(
                          iconTheme: quill.QuillIconTheme(
                              iconButtonSelectedData: quill.IconButtonData(
                                  color: Colors.white,
                                  highlightColor: Colors.grey),
                              iconButtonUnselectedData:
                              quill.IconButtonData(color: Colors.grey)
                          )
                      ),
                      bold: quill.QuillToolbarToggleStyleButtonOptions(
                          iconTheme: quill.QuillIconTheme(
                              iconButtonSelectedData:
                              quill.IconButtonData(color: Colors.white, highlightColor: Colors.grey, splashColor: Colors.grey),
                              iconButtonUnselectedData: quill.IconButtonData(
                                color: Colors.grey,
                              )
                          )
                      ),
                      italic: quill.QuillToolbarToggleStyleButtonOptions(
                          iconTheme: quill.QuillIconTheme(
                              iconButtonSelectedData:
                              quill.IconButtonData(color: Colors.white, highlightColor: Colors.grey, splashColor: Colors.grey),
                              iconButtonUnselectedData: quill.IconButtonData(
                                color: Colors.grey,
                              )
                          )
                      ),
                      underLine: quill.QuillToolbarToggleStyleButtonOptions(
                          iconTheme: quill.QuillIconTheme(
                              iconButtonSelectedData:
                              quill.IconButtonData(color: Colors.white, highlightColor: Colors.grey, splashColor: Colors.grey),
                              iconButtonUnselectedData: quill.IconButtonData(
                                color: Colors.grey,
                              )
                          )
                      ),
                      redoHistory: quill.QuillToolbarHistoryButtonOptions(
                          iconTheme: quill.QuillIconTheme(
                              iconButtonSelectedData: quill.IconButtonData(
                                  color: Colors.white,
                                  highlightColor: Colors.grey),
                              iconButtonUnselectedData:
                              quill.IconButtonData(color: Colors.grey, highlightColor: Colors.grey)
                          )
                      ),
                      fontSize: quill.QuillToolbarFontSizeButtonOptions(defaultItemColor: Colors.grey, style: TextStyle(color: Colors.grey)),
                      strikeThrough: quill.QuillToolbarToggleStyleButtonOptions(
                          iconTheme: quill.QuillIconTheme(
                              iconButtonSelectedData:
                              quill.IconButtonData(color: Colors.white, highlightColor: Colors.grey, splashColor: Colors.grey),
                              iconButtonUnselectedData: quill.IconButtonData(
                                color: Colors.grey,
                              )
                          )
                      )
                  )
              ),
            ),
          if (widget.categoryName == 'Journal' || widget.categoryName == 'Gefühle')
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                cursorColor: Colors.black,
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Short Description',
                  focusColor: Colors.blue,
                  labelStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey, width: 3)),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              children: [quill.QuillEditor(
                controller: _controller,
                scrollController: ScrollController(),
                focusNode: FocusNode(),
              ),
                const SizedBox(height: 20),
                // Audio recording controls
                _buildAudioRecorder(),
                const SizedBox(height: 20),
                ...widget.audioNotes.map((audioNote) {
                  return ListTile(
                    leading: IconButton(
                      icon: Icon(
                        _isPlaying && _currentlyPlayingAudio == audioNote.filePath
                            ? Icons.stop
                            : Icons.play_arrow,
                      ),
                      onPressed: () {
                        // Implement playback
                        _playAudio(audioNote.filePath);
                      },
                    ),
                    title: Text(audioNote.title),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        widget.onDeleteAudio(audioNote);
                      },
                    ),
                  );
                }).toList(),
              ],

            ),
          ),

        ],
      ),
    );
  }

  Widget _buildAudioRecorder() {
    return Column(
      children: [
        if (_isRecording)
          const Text(
            'Recording...',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
          ],
        ),
      ],
    );
  }
}
