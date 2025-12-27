class Question {
  final String id;
  final String text;
  final List<String> options;

  Question({
    required this.id,
    required this.text,
    required this.options,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      options: (json['options'] as List).map((e) => e.toString()).toList(),
    );
  }
}
//speichert eine Frage mit id,text und optionen
//fromJson baut aus dem JSON objekt eine Question