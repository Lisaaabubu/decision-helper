import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/question.dart';
import '../models/training_user.dart';

class DataService {
  Future<List<Question>> loadQuestions() async {
    final raw = await rootBundle.loadString('assets/questions.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TrainingUser>> loadTrainingUsers() async {
    final raw = await rootBundle.loadString('assets/user_training_data.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => TrainingUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
