import 'package:flutter/material.dart';

import '../models/question.dart';
import '../models/training_user.dart';
import '../models/question_answer_result.dart';
import '../services/recommender_service.dart';

const Map<String, List<String>> whyOptionsPerQuestion =
{
  "Q4": [
    "Einsteigerfreundlich",
    "Funktionsumfang",
    "Performance",
    "Gewohnheit",
    "Vorgabe (Uni/FH/Job)",
  ],
};

const Map<String, String> ideIconByOption =
{
  "VS Code": "assets/images/vscode.png",
  "IntelliJ": "assets/images/intellij.png",
  "Android Studio": "assets/images/androidstudio.png",
  "Vim": "assets/images/vim.png",
};


class QuestionDetailScreen extends StatefulWidget
{
  final Question question;
  final String? initialAnswer;

  final List<Question> questions;
  final List<TrainingUser> trainingUsers;
  final Map<String, String> currentAnswers;
  final int k;

  const QuestionDetailScreen({
    super.key,
    required this.question,
    this.initialAnswer,
    required this.questions,
    required this.trainingUsers,
    required this.currentAnswers,
    this.k = 3,
  });

  @override
  State<QuestionDetailScreen> createState()
  {
    return _QuestionDetailScreenState();
  }
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen>
{
  String? selected;
  String? selectedWhy;

  final RecommenderService _recommender = RecommenderService();
  late Map<String, String> _previewAnswers;

  @override
  void initState()
  {
    super.initState();

    selected = widget.initialAnswer;
    _previewAnswers = Map<String, String>.from(widget.currentAnswers);

    if (selected != null)
    {
      _previewAnswers[widget.question.id] = selected!;
    }
  }

  @override
  Widget build(BuildContext context)
  {
    final q = widget.question;
    final String qId = q.id;

    final bool showHelperCard = qId == "Q1"
        ? selected != null
        : true;

    final bool hasWhyOptions = whyOptionsPerQuestion.containsKey(qId);
    final bool showWhyBlock = hasWhyOptions && selected != null;

    final Map<String, String> tempAnswers = Map<String, String>.from(_previewAnswers);
    if (selected != null)
    {
      tempAnswers[qId] = selected!;
    }

    final neighbours = _recommender.findNearestNeighbours(
      currentAnswers: tempAnswers,
      trainingUsers: widget.trainingUsers,
      questions: widget.questions,
      k: widget.k,
    );

    final freqs = _recommender.calculateFrequencies(neighbours, [q]);
    final counts = freqs[qId] ?? {};

    String? recommended;
    int topCount = 0;

    if (counts.isNotEmpty)
    {
      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      recommended = sorted.first.key;
      topCount = sorted.first.value;
    }

    final double confidence = neighbours.isEmpty
        ? 0.0
        : topCount / neighbours.length;

    final int votesTotal = _recommender.totalVotesForQuestion(
      qId,
      widget.trainingUsers,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(q.id),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.text,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    ...q.options.map((opt)
                    {
                      final bool isQ4 = qId == "Q4";

                        if (isQ4)
                        {
                          final iconPath = ideIconByOption[opt];

                          return RadioListTile<String>(
                            value: opt,
                            groupValue: selected,
                            onChanged: (v)
                            {
                              setState(()
                              {
                                selected = v;

                                if (v != null)
                                {
                                  _previewAnswers[qId] = v;
                                }
                                else
                                {
                                  _previewAnswers.remove(qId);
                                }
                              });
                            },
                            title: Row(
                              children: [
                                if (iconPath != null) ...[
                                  Image.asset(
                                    iconPath,
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Text(opt),
                              ],
                            ),
                          );
                        }

                        return RadioListTile<String>(
                          title: Text(opt),
                          value: opt,
                          groupValue: selected,
                          onChanged: (v)
                          {
                            setState(()
                            {
                              selected = v;

                              if (v != null)
                              {
                                _previewAnswers[qId] = v;
                              }
                              else
                              {
                                _previewAnswers.remove(qId);
                              }
                            });
                          },
                        );
                      }).toList(),

                    if (showHelperCard) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Entscheidungshilfe (KNN, k=${widget.k})',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),

                              Text('Trainingsbasis: $votesTotal Votes'),
                              Text('Ähnliche Nutzer: ${neighbours.map((u) => u.userId).join(", ")}'),

                              const SizedBox(height: 8),

                              Text(
                                'Empfehlung: ${recommended ?? "(noch keine)"}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('Confidence: ${(confidence * 100).toStringAsFixed(0)}%'),

                              const SizedBox(height: 10),
                              const Text('Häufigkeit bei ähnlichen Nutzern:'),
                              const SizedBox(height: 6),

                              ...q.options.map((opt)
                              {
                                final int c = counts[opt] ?? 0;
                                return Text(' - $opt: $c');
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (showWhyBlock) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Warum hast du dich dafür entschieden?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),

                      ...whyOptionsPerQuestion[qId]!.map((reason)
                      {
                        return RadioListTile<String>(
                          title: Text(reason),
                          value: reason,
                          groupValue: selectedWhy,
                          onChanged: (v)
                          {
                            setState(()
                            {
                              selectedWhy = v;
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selected == null
                      ? null
                      : ()
                      {
                          Navigator.pop(
                            context,
                            QuestionAnswerResult(
                              answer: selected!,
                              why: selectedWhy,
                            ),
                          );
                        },
                  child: const Text('Speichern'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
