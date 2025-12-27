import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/training_user.dart';
import '../services/recommender_service.dart';

class RecommendationScreen extends StatelessWidget {
  final List<Question> questions;
  final List<TrainingUser> trainingUsers;
  final Map<String, String> currentAnswers;
  final int k;

  const RecommendationScreen({
    super.key,
    required this.questions,
    required this.trainingUsers,
    required this.currentAnswers,
    this.k = 3,
  });

  @override
  Widget build(BuildContext context) {
    final recommender = RecommenderService();

    final neighbours = recommender.findNearestNeighbours(
      currentAnswers: currentAnswers,
      trainingUsers: trainingUsers,
      questions: questions,
      k: k,
    );

    final freqs = recommender.calculateFrequencies(neighbours, questions);

    String? recommendedAnswer(String qId) {
      final counts = freqs[qId] ?? {};
      if (counts.isEmpty) return null;
      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sorted.first.key;
    }

    Map<String, int> fullCounts(Question q) {
      final counts = freqs[q.id] ?? {};
      // Alle Optionen inkl. 0
      return {
        for (final opt in q.options) opt: (counts[opt] ?? 0),
      };
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Empfehlungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'KNN (K=$k) – Top-${neighbours.length} ähnliche Nutzer: '
            '${neighbours.map((u) => u.userId).join(", ")}',
          ),
          const SizedBox(height: 16),

          ...questions.map((q) {
            final own = currentAnswers[q.id];
            final rec = recommendedAnswer(q.id);
            final counts = fullCounts(q);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${q.id}: ${q.text}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Deine Antwort: ${own ?? "(keine)"}'),
                    Text('Empfehlung: ${rec ?? "(keine)"}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text('Ähnliche Nutzer antworteten:'),
                    const SizedBox(height: 6),
                    ...counts.entries.map((e) => Text(' - ${e.key}: ${e.value}')),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
