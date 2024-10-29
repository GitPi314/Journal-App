class JournalEntry {
  final String content;
  final String description;

  JournalEntry({required this.content, required this.description});

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'description': description,
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      content: json['content'],
      description: json['description'],
    );
  }
}
