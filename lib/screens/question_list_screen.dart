import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/training_user.dart';
import 'question_detail_screen.dart';
import 'recommendation_screen.dart';


class QuestionListScreen extends StatefulWidget {
  final List<Question> questions;
  final List<TrainingUser> trainingUsers;

  const QuestionListScreen({
    super.key,
    required this.questions,
    required this.trainingUsers,
  });

  @override
  State<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  final Map<String, String> currentAnswers = {}; // QID -> selected answer

  bool get allAnswered => currentAnswers.length == widget.questions.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decision Helper')),

      body: ListView.builder(
        itemCount: widget.questions.length,
        itemBuilder: (context, index) {
          final q = widget.questions[index];
          final selected = currentAnswers[q.id];

          return ListTile(
            title: Text(q.text),
            subtitle: selected == null
                ? const Text('Noch nicht beantwortet')
                : Text('Deine Antwort: $selected'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final answer = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => QuestionDetailScreen(
                    question: q,
                    initialAnswer: selected,
                  ),
                ),
              );

              if (answer != null) {
                setState(() => currentAnswers[q.id] = answer);
              }
            },
          );
        },
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: allAnswered
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecommendationScreen(
                          questions: widget.questions,
                          trainingUsers: widget.trainingUsers,
                          currentAnswers: currentAnswers,
                          k: 3,
                        ),
                      ),
                    );
                  }
                : null,
            child: const Text('Empfehlungen anzeigen'),
          ),
        ),
      ),
    );
  }

}
