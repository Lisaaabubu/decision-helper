import 'package:flutter/material.dart';

import '../models/question.dart';
import '../models/training_user.dart';
import '../models/question_answer_result.dart';
import 'question_detail_screen.dart';
import 'recommendation_screen.dart';

class QuestionListScreen extends StatefulWidget
{
  final List<Question> questions;
  final List<TrainingUser> trainingUsers;

  const QuestionListScreen({
    super.key,
    required this.questions,
    required this.trainingUsers,
  });

  @override
  State<QuestionListScreen> createState()
  {
    return _QuestionListScreenState();
  }
}

class _QuestionListScreenState extends State<QuestionListScreen>
{
  final Map<String, String> currentAnswers = {};
  final Map<String, String> currentWhys = {};

  bool get allAnswered
  {
    return currentAnswers.length == widget.questions.length;
  }

  bool get atLeastOneAnswered
  {
    return currentAnswers.isNotEmpty;
  }

  @override
  Widget build(BuildContext context)
  {
    final String buttonText = allAnswered
        ? 'Empfehlungen anzeigen'
        : 'Empfehlungen anzeigen (Zwischenstand)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Decision Helper'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/titel_image.png',
                  height: 180,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                Text(
                  'Decision Helper',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Diese App unterstützt bei Entscheidungen auf Basis ähnlicher Nutzerprofile (KNN).',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: widget.questions.length,
              itemBuilder: (context, index)
              {
                final q = widget.questions[index];
                final selected = currentAnswers[q.id];
                final why = currentWhys[q.id];

                final String subtitleText = selected == null
                    ? 'Noch nicht beantwortet'
                    : (why == null || why.isEmpty)
                        ? 'Deine Antwort: $selected'
                        : 'Deine Antwort: $selected\nWarum: $why';

                return ListTile(
                  title: Text(q.text),
                  subtitle: Text(subtitleText),
                  trailing: const Icon(Icons.chevron_right),
                  isThreeLine: why != null && why.isNotEmpty,
                  onTap: () async
                  {
                    final result = await Navigator.push<QuestionAnswerResult>(
                      context,
                      MaterialPageRoute(
                        builder: (context)
                        {
                          return QuestionDetailScreen(
                            question: q,
                            initialAnswer: selected,
                            questions: widget.questions,
                            trainingUsers: widget.trainingUsers,
                            currentAnswers: currentAnswers,
                            k: 3,
                          );
                        },
                      ),
                    );

                    if (result != null)
                    {
                      setState(()
                      {
                        currentAnswers[q.id] = result.answer;

                        if (result.why != null && result.why!.isNotEmpty)
                        {
                          currentWhys[q.id] = result.why!;
                        }
                        else
                        {
                          currentWhys.remove(q.id);
                        }
                      });
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: atLeastOneAnswered
                ? ()
                {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context)
                        {
                          return RecommendationScreen(
                            questions: widget.questions,
                            trainingUsers: widget.trainingUsers,
                            currentAnswers: currentAnswers,
                            k: 3,
                          );
                        },
                      ),
                    );
                  }
                : null,
            child: Text(buttonText),
          ),
        ),
      ),
    );
  }
}
