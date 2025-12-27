class TrainingUser {
  final int userId;
  final Map<String, String> answers; // z.B. {"Q1":"Laptop", ...}

  TrainingUser({
    required this.userId,//Zahl aber String
    required this.answers,//eine Map mit QuestionID zu Antworttext
  });

  factory TrainingUser.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as Map<String, dynamic>;

    return TrainingUser(
      userId: json['userId'] as int,
      answers: rawAnswers.map((key, value) => MapEntry(key, value.toString())),
    );
  }
}
