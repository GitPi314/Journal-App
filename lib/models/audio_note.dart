// models/audio_note.dart

class AudioNote {
  final String filePath;
  final String title;

  AudioNote({required this.filePath, required this.title});

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'title': title,
    };
  }

  factory AudioNote.fromJson(Map<String, dynamic> json) {
    return AudioNote(
      filePath: json['filePath'],
      title: json['title'],
    );
  }
}
