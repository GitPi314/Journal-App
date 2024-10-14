import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'dart:async';  // Import for Timer
//import '../services/storage_service.dart';

class NoteSection extends StatefulWidget {
  final Color backgroundColor;
  final Function(String) onContentChanged;
  final String initialContent;
  final String initialDescription;
  final Function(String) onDescriptionChanged;

  const NoteSection({
    super.key,
    required this.backgroundColor,
    required this.onContentChanged,
    required this.initialContent,
    required this.initialDescription,
    required this.onDescriptionChanged,
  });

  @override
  _NoteSectionState createState() => _NoteSectionState();
}

class _NoteSectionState extends State<NoteSection> {
  late quill.QuillController _controller;
  Timer? _autoSaveTimer;  // Declare a Timer for auto-saving
  String _currentContent = '';
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _controller.addListener(_onContentChanged);
    _descriptionController.addListener(_onDescriptionChanged);
    _startAutoSaveTimer();  // Start the timer when the widget is initialized
  }

  // Initialize the QuillController with the initial content
  void _initializeController() {
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

  @override
  void didUpdateWidget(NoteSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialContent != oldWidget.initialContent) {
      _controller.removeListener(_onContentChanged);
      _initializeController();
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
            child: Container(
              padding: const EdgeInsets.all(16),
              child: quill.QuillEditor(
                controller: _controller,
                scrollController: ScrollController(),
                focusNode: FocusNode(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
