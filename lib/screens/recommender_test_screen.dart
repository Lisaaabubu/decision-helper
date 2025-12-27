import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/training_user.dart';
import '../services/recommender_service.dart';

class RecommenderTestScreen extends StatelessWidget {
  final List<Question> questions;
  final List<TrainingUser> trainingUsers;

  const RecommenderTestScreen({
    super.key,
    required this.questions,
    required this.trainingUsers,
  });

  @override
  Widget build(BuildContext context) {
    final recommender = RecommenderService();

    // ✅ Test-User (simuliert "deine" Antworten)
    final currentAnswers = <String, String>{
      "Q1": "Laptop",
      "Q2": "Abends",
      "Q3": "VS Code",
    };

    final neighbours = recommender.findNearestNeighbours(
      currentAnswers: currentAnswers,
      trainingUsers: trainingUsers,
      questions: questions,
      k: 3,
    );

    final freqs = recommender.calculateFrequencies(neighbours, questions);

    // Empfehlung: häufigste Antwort pro Frage
    String? recommendedAnswer(String qId) {
      final counts = freqs[qId] ?? {};
      if (counts.isEmpty) return null;
      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sorted.first.key;
    }

    String formatCounts(String qId, Question q) {
      final counts = freqs[qId] ?? {};
      // Wir zeigen ALLE Optionen, auch wenn 0
      return q.options
          .map((opt) => " - $opt: ${counts[opt] ?? 0}")
          .join("\n");
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Recommender Mini-Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text("Aktueller User (Test):", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(currentAnswers.entries.map((e) => "${e.key}: ${e.value}").join("\n")),
            const SizedBox(height: 16),

            const Text("Top-3 Nachbarn (userId):", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(neighbours.map((u) => u.userId).join(", ")),
            const SizedBox(height: 16),

            const Divider(),
            const Text("Empfehlungen:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            ...questions.map((q) {
              final rec = recommendedAnswer(q.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${q.id}: ${q.text}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Deine Antwort: ${currentAnswers[q.id] ?? "(keine)"}"),
                    Text("Empfehlung: ${rec ?? "(keine)"}"),
                    const SizedBox(height: 6),
                    Text("Ähnliche Nutzer antworteten:\n${formatCounts(q.id, q)}"),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
