import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
//import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'dart:async';  // Import for Timer
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';


class NoteSection extends StatefulWidget {
  final Color backgroundColor;
  final Function(String) onContentChanged;
  final String initialContent;
  final String initialDescription;
  final Function(String) onDescriptionChanged;
  final String categoryName;
  final ValueChanged<bool> onRecordingStateChanged;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  //final VoidCallback onStartRecording;

  const NoteSection({
    super.key,
    required this.backgroundColor,
    required this.onContentChanged,
    required this.initialContent,
    required this.initialDescription,
    required this.onDescriptionChanged,
    required this.categoryName,
    required this.onRecordingStateChanged,
    required this.onStartRecording,
    required this.onStopRecording,
    required bool isRecording,
    //required this.onStartRecording,
  });

  @override
  NoteSectionState createState() => NoteSectionState();
}

class NoteSectionState extends State<NoteSection> {
  late quill.QuillController _controller;
  late ScrollController _scrollController;
  late FocusNode _focusNode;
  Timer? _autoSaveTimer;  // Declare a Timer for auto-saving
  String _currentContent = '';
  late TextEditingController _descriptionController;

  bool _isRecording = false;
  bool _isPaused = false;
  bool _isDescriptionExpanded = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  late String _filePath;


  FlutterSoundRecorder? _audioRecorder;
  final RecorderController _recorderController = RecorderController();

  @override
  void initState() {
    super.initState();
    _initializeQuillController();
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _controller.addListener(_onContentChanged);
    _descriptionController.addListener(_onDescriptionChanged);
    /*
    widget.onStartRecording = () {
      setState(() {
        _isRecording = true;
      });
    };

     */
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    _startAutoSaveTimer();  // Start the timer when the widget is initialized
    _audioRecorder = FlutterSoundRecorder();
    _initializeRecorder();
  }

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

  Future<void> _initializeRecorder() async {
    _audioRecorder ??= FlutterSoundRecorder();

    // Mikrofonberechtigung anfordern
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Mikrofonberechtigung nicht erteilt');
    }

    // Recorder öffnen
    await _audioRecorder!.openRecorder();
  }





  void _onDescriptionChanged() {
    widget.onDescriptionChanged(_descriptionController.text);
  }


  void _onContentChanged() {
    var json = jsonEncode(_controller.document.toDelta().toJson());
    _currentContent = json;  // Update the current content
    widget.onContentChanged(json);
  }
  // Function to start the auto-save timer
  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        if (_currentContent.isNotEmpty) {
          widget.onContentChanged(_currentContent);
        }
      } else {
        timer.cancel();
      }
    });
  }

  void onStartRecording() async {
    try {
      await _initializeRecorder();

      // Temporären Pfad für die Aufnahme erhalten
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _audioRecorder!.startRecorder(
        toFile: tempPath,
        codec: Codec.aacADTS,
      );

      _filePath = tempPath;

      _recorderController.record(); // Waveform-Aufnahme starten
      _startTimer(); // Timer starten

      setState(() {
        _isRecording = true;
      });

      widget.onRecordingStateChanged(_isRecording); // Eltern-Widget benachrichtigen
    } catch (e) {
      print('Error starting recording: $e');
      setState(() {
        _isRecording = false;
      });
      widget.onRecordingStateChanged(_isRecording);
    }
  }






  void _pauseOrResumeRecording() async {
    if (_isPaused) {
      await _audioRecorder?.resumeRecorder();
      _recorderController.record();
      _startTimer();
    } else {
      await _audioRecorder?.pauseRecorder();
      _recorderController.pause();
      _pauseTimer();
    }
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _stopAndSaveRecording() async {
    try {
      _filePath = (await _audioRecorder!.stopRecorder())!;
      await _audioRecorder!.closeRecorder();
      _recorderController.stop();
      _stopTimer();
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
      widget.onRecordingStateChanged(_isRecording);
      _insertAudioIntoNote();
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }



  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) { // Prüfen, ob Widget noch aktiv ist
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      } else {
        timer.cancel(); // Timer abbrechen, wenn Widget nicht mehr aktiv ist
      }
    });
  }


  void _pauseTimer() {
    _timer?.cancel();
  }

  void _stopTimer() {
    _timer?.cancel();
    _recordingDuration = Duration.zero;
  }

  void _insertAudioIntoNote() {
    print('Inserting audio into note...');
    final String audioFilePath = _filePath;
    final String audioName = 'Audio_${DateTime.now().millisecondsSinceEpoch}';

    Map<String, dynamic> attributes = {
      'filePath': audioFilePath,
      'name': audioName,
    };

    var index = _controller.selection.baseOffset;

    _controller.document.insert(
      index,
      AudioBlockEmbed.fromData(attributes),
    );

    // Cursorposition aktualisieren
    _controller.updateSelection(
      TextSelection.collapsed(offset: index + 1),
      quill.ChangeSource.local,
    );
    print('Audio file saved at: $_filePath');

  }




  @override
  void dispose() {
    _controller.dispose();
    _descriptionController.dispose();
    _autoSaveTimer?.cancel();  // Cancel the auto-save timer when the widget is disposed
    _timer?.cancel();
    _scrollController.dispose();
    _focusNode.dispose();
    //_audioTitleController.dispose();
    if (_audioRecorder != null && !_audioRecorder!.isStopped) {
      _audioRecorder!.stopRecorder();
    }
    _audioRecorder?.closeRecorder();
    _audioRecorder = null;
    _recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.lerp(widget.backgroundColor, Colors.white, 0.5),
      child: Column(
        children: [
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
                showClearFormat: true, //durchgestrichenes T
                color: Colors.grey[700],
                buttonOptions: const quill.QuillSimpleToolbarButtonOptions(
                    undoHistory: quill.QuillToolbarHistoryButtonOptions(
                        iconTheme: quill.QuillIconTheme(
                            iconButtonSelectedData: quill.IconButtonData(
                                color: Colors.white,
                                highlightColor: Colors.grey),
                            iconButtonUnselectedData:
                            quill.IconButtonData(color: Colors.white, disabledColor: Colors.grey)
                        )
                    ),
                    redoHistory: quill.QuillToolbarHistoryButtonOptions(
                        iconTheme: quill.QuillIconTheme(
                            iconButtonSelectedData: quill.IconButtonData(
                              color: Colors.white,
                              highlightColor: Colors.grey, ),
                            iconButtonUnselectedData:
                            quill.IconButtonData(color: Colors.white, highlightColor: Colors.grey, disabledColor: Colors.grey)
                        )
                    ),
                    bold: quill.QuillToolbarToggleStyleButtonOptions(
                        iconTheme: quill.QuillIconTheme(
                            iconButtonSelectedData:
                            quill.IconButtonData(color: Colors.white, highlightColor: Colors.grey),
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

                    fontSize: quill.QuillToolbarFontSizeButtonOptions(defaultItemColor: Colors.grey, style: TextStyle(color: Colors.grey), ),
                    strikeThrough: quill.QuillToolbarToggleStyleButtonOptions(
                        iconTheme: quill.QuillIconTheme(
                            iconButtonSelectedData:
                            quill.IconButtonData(color: Colors.white, highlightColor: Colors.grey, splashColor: Colors.grey),
                            iconButtonUnselectedData: quill.IconButtonData(
                              color: Colors.grey,
                            )
                        )
                    ),
                  color: quill.QuillToolbarColorButtonOptions(iconTheme: quill.QuillIconTheme(iconButtonSelectedData: quill.IconButtonData(color: Colors.white, highlightColor: Colors.grey, splashColor: Colors.grey),
                      iconButtonUnselectedData: quill.IconButtonData(
                        color: Colors.grey,
                      ))),
                  listBullets: quill.QuillToolbarToggleStyleButtonOptions(iconTheme: quill.QuillIconTheme(
                      iconButtonSelectedData:
                      quill.IconButtonData(color: Colors.white, highlightColor: Colors.grey, splashColor: Colors.grey),
                      iconButtonUnselectedData: quill.IconButtonData(
                        color: Colors.grey,
                      )
                  )),
                  listNumbers: quill.QuillToolbarToggleStyleButtonOptions(iconTheme: quill.QuillIconTheme(
                      iconButtonSelectedData:
                      quill.IconButtonData(color: Colors.white, highlightColor: Colors.grey, splashColor: Colors.grey),
                      iconButtonUnselectedData: quill.IconButtonData(
                        color: Colors.grey,
                      )
                  )),
                  search: quill.QuillToolbarSearchButtonOptions(iconTheme: quill.QuillIconTheme(
                      iconButtonSelectedData: quill.IconButtonData(
                          color: Colors.white,
                          highlightColor: Colors.grey),
                      iconButtonUnselectedData:
                      quill.IconButtonData(color: Colors.grey, highlightColor: Colors.grey)
                  )),
                  backgroundColor: quill.QuillToolbarColorButtonOptions(iconTheme: quill.QuillIconTheme(iconButtonSelectedData: quill.IconButtonData(color: Colors.white, highlightColor: Colors.grey, splashColor: Colors.grey),
                      iconButtonUnselectedData: quill.IconButtonData(
                        color: Colors.grey,
                      ))),
                  clearFormat: quill.QuillToolbarClearFormatButtonOptions(iconTheme: quill.QuillIconTheme(
                      iconButtonSelectedData:
                      quill.IconButtonData(color: Colors.white, highlightColor: Colors.grey, splashColor: Colors.grey),
                      iconButtonUnselectedData: quill.IconButtonData(
                        color: Colors.grey,
                      )
                  ) ),
                  toggleCheckList: quill.QuillToolbarToggleCheckListButtonOptions(iconTheme: quill.QuillIconTheme(
                      iconButtonSelectedData:
                      quill.IconButtonData(color: Colors.white, highlightColor: Colors.grey, splashColor: Colors.grey),
                      iconButtonUnselectedData: quill.IconButtonData(
                        color: Colors.grey,
                      )
                  ))

                ),

            ),
          ),
          if (widget.categoryName == 'Journal' || widget.categoryName == 'Gefühle')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      firstChild: Container(), // Eingeklappter Zustand
                      secondChild: TextField(
                        cursorColor: Colors.black,
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Short Description',
                          focusColor: Colors.blue,
                          labelStyle: TextStyle(color: Colors.grey),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey, width: 3),
                          ),
                        ),
                      ),
                      crossFadeState: _isDescriptionExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isDescriptionExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                  ),
                ],
              ),
            ),
          //quill.QuillToolbar.basic(controller: _controller),
          Expanded(
            child: Column(
              children: [ //staer
                Expanded(
                  child: quill.QuillEditor(
                    controller: _controller,
                    scrollController: _scrollController,
                    focusNode: _focusNode,
                    configurations: quill.QuillEditorConfigurations(
                      embedBuilders: [
                        CustomAudioEmbedBuilder(), // Dein benutzerdefinierter EmbedBuilder
                      ],
                    ),
                  ),
                ),
                if (_isRecording) _buildRecordingBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8), // Fügt seitlichen Abstand hinzu
      child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.grey[700], // Hellerer Hintergrund
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3), // Schatten nach unten
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Anzeige der Aufnahmezeit
              Text(
                _formatDuration(_recordingDuration),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              // Waveform und Play/Pause Button nebeneinander
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    fit: FlexFit.tight,
                    child: AudioWaveforms(
                      recorderController: _recorderController,
                      waveStyle: const WaveStyle(
                        waveColor: Colors.blue,
                        showMiddleLine: true,
                        waveCap: StrokeCap.round,
                      ),
                      size: const Size(double.infinity, 50.0),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.square),
                      iconSize: _isPaused ? 40 : 28,
                      padding: EdgeInsets.zero, // Entfernt zusätzliches Padding
                      onPressed: _pauseOrResumeRecording,
                      color: _isPaused ? Colors.black : Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Bestätigen-Icon darunter
              IconButton(
                icon: const Icon(Icons.check),
                iconSize: 40,
                onPressed: _stopAndSaveRecording,
                color: Colors.green,
              ),
            ],
          )

      ),
    );
  }


  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String minutes = twoDigits(duration.inMinutes.remainder(60));
    final String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class AudioBlockEmbed extends quill.CustomBlockEmbed {
  static const String audioType = 'audio';

  AudioBlockEmbed(String data)
      : super(audioType, data);

  static AudioBlockEmbed fromData(Map<String, dynamic> data) {
    return AudioBlockEmbed(jsonEncode(data));
  }

  Map<String, dynamic> get audioData => jsonDecode(data);
}








class CustomAudioEmbedBuilder extends quill.EmbedBuilder {
  @override
  String get key => 'audio';

  @override
  Widget build(
      BuildContext context,
      quill.QuillController controller,
      quill.Embed node,
      bool readOnly,
      bool inline,
      TextStyle textStyle,
      ) {
    final String dataString = node.value.data;
    final Map<String, dynamic> data = jsonDecode(dataString);
    final String filePath = data['filePath'];
    final String name = data['name'] ?? 'Audio Recording';

    print('Building audio widget with filePath: $filePath');

    return AudioPlayerWidget(
      filePath: filePath,
      initialName: name,
      controller: controller,
    );
  }
}




class AudioPlayerWidget extends StatefulWidget {
  final String filePath;
  final String initialName;
  final quill.QuillController controller;

  const AudioPlayerWidget({
    super.key,
    required this.filePath,
    required this.initialName,
    required this.controller,
  });

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  FlutterSoundPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  TextEditingController? _nameController;
  Timer? _progressTimer;

  final PlayerController _playerController = PlayerController();

  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = FlutterSoundPlayer();
    _audioPlayer!.openPlayer();
    _nameController = TextEditingController(text: widget.initialName);
    _playerController.preparePlayer(
      path: widget.filePath,
      shouldExtractWaveform: true,
    );
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer!.pausePlayer();
      _playerController.pausePlayer();
      _progressTimer?.cancel();  // Stop the progress timer when pausing
    } else {
      await _audioPlayer!.startPlayer(
        fromURI: widget.filePath,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _currentPosition = Duration.zero;
            _playerController.stopPlayer();
          });
          _progressTimer?.cancel();  // Stop the progress timer when finished
        },
      );
      _audioPlayer!.setSubscriptionDuration(const Duration(milliseconds: 100));

      _audioPlayer!.onProgress!.listen((event) {
        if (mounted) {
          setState(() {
            _currentPosition = event.position;
          });
        }
      });  // Start tracking progress
      _playerController.startPlayer();
    }
    if (mounted) {
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  void _toggleEditingName() {
    setState(() {
      _isEditingName = !_isEditingName;
    });
  }

  void _deleteAudioBlock() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Audio löschen'),
          content: const Text('Möchten Sie dieses Audio wirklich löschen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                _removeAudioBlock();
                Navigator.of(context).pop();
              },
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );
  }

  void _removeAudioBlock() {
    final index = _getEmbedIndex();

    if (index != -1) {
      widget.controller.replaceText(
        index,
        1,
        '',
        quill.ChangeSource.local as TextSelection?,
      );
    }
  }

  int _getEmbedIndex() {
    final doc = widget.controller.document;
    int offset = 0;

    for (var node in doc.root.children) {
      if (node is quill.Line) {
        for (var leaf in node.children) {
          if (leaf is quill.Embed) {
            if (leaf.value.type == 'audio') {
              final data = jsonDecode(leaf.value.data);
              if (data['filePath'] == widget.filePath) {
                return offset;
              }
            }
          }
          offset += leaf.length;
        }
      } else {
        offset += node.length;
      }
    }

    return -1;
  }

  @override
  void dispose() {
    _audioPlayer?.closePlayer();
    _audioPlayer = null;
    _nameController!.dispose();
    _playerController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String minutes = twoDigits(duration.inMinutes.remainder(60));
    final String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _updateEmbedName(String newName) {
    final index = _getEmbedIndex();

    if (index != -1) {
      final attributes = {
        'filePath': widget.filePath,
        'name': newName,
      };

      widget.controller.replaceText(
        index,
        1,
        AudioBlockEmbed.fromData(attributes),
        quill.ChangeSource.local as TextSelection?,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 2.0, right: 2,),
      child: GestureDetector(
        onLongPress: _deleteAudioBlock,
        child: Container(
          padding: const EdgeInsets.only(left: 8.0, right: 8, top: 5,bottom: 5),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: Colors.black54,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name und Bearbeiten-Icon direkt nebeneinander
              IntrinsicWidth(
                child: Row(
                  children: [
                    // Text oder TextField als Name, je nach Bearbeitungsmodus
                    _isEditingName
                        ? Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Audio Name',
                        ),
                        onSubmitted: (value) {
                          _updateEmbedName(value);
                          _toggleEditingName();
                        },
                      ),
                    )
                        : Text(
                      _nameController!.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    //const SizedBox(width: 4), // Abstand zwischen Text und Icon
                    IconButton(
                      icon: Icon(
                        _isEditingName ? Icons.edit_off : Icons.edit,
                        color: _isEditingName ? Colors.grey : Colors.black,
                        size: 18,
                      ),
                      onPressed: _toggleEditingName,
                    ),
                  ],
                ),
              ),
              //const SizedBox(height: 8),
              // Wellenform, Timer und Wiedergabe-Steuerelemente
              Container(
                padding: const EdgeInsets.only(left: 8, right: 8),
                /*
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(25.0),
              ),

               */
                child: Row(
                  children: [
                    // Timer
                    Text(_formatDuration(_currentPosition)),
                    const SizedBox(width: 10),
                    // Waveform
                    Expanded(
                      child: AudioFileWaveforms(
                        playerController: _playerController,
                        size: const Size(double.infinity, 50.0),
                        waveformType: WaveformType.fitWidth,
                        playerWaveStyle: const PlayerWaveStyle(
                          fixedWaveColor: Colors.blue,
                          liveWaveColor: Colors.blueAccent,
                          showSeekLine: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Play/Pause Button
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_circle_outline),
                      onPressed: _togglePlayPause,
                      color: Colors.green,
                      iconSize: 40,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
