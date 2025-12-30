import 'package:flutter/material.dart';

import '../models/question.dart';
import '../models/training_user.dart';
import '../services/recommender_service.dart';

class RecommendationScreen extends StatelessWidget
{
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
  Widget build(BuildContext context)
  {
    final RecommenderService recommender = RecommenderService();

    final List<TrainingUser> neighbours = recommender.findNearestNeighbours(
      currentAnswers: currentAnswers,
      trainingUsers: trainingUsers,
      questions: questions,
      k: k,
    );

    final Map<String, Map<String, int>> freqs = recommender.calculateFrequencies(
      neighbours,
      questions,
    );

    String? recommendedAnswer(String qId)
    {
      final counts = freqs[qId] ?? {};
      if (counts.isEmpty)
      {
        return null;
      }

      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.first.key;
    }

    int topCountFor(String qId)
    {
      final counts = freqs[qId] ?? {};
      if (counts.isEmpty)
      {
        return 0;
      }

      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.first.value;
    }

    Map<String, int> fullCounts(Question q)
    {
      final counts = freqs[q.id] ?? {};

      return {
        for (final opt in q.options) opt: (counts[opt] ?? 0),
      };
    }

    int totalVotesAllQuestions()
    {
      int sum = 0;

      for (final q in questions)
      {
        sum += recommender.totalVotesForQuestion(q.id, trainingUsers);
      }

      return sum;
    }

    final int totalVotes = totalVotesAllQuestions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Empfehlungen'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(
            k: k,
            neighbours: neighbours,
            totalVotes: totalVotes,
          ),

          const SizedBox(height: 16),

          ...questions.map((q)
          {
            final String? own = currentAnswers[q.id];
            final String? rec = recommendedAnswer(q.id);

            final Map<String, int> counts = fullCounts(q);

            final int topCount = topCountFor(q.id);
            final double confidence = neighbours.isEmpty
                ? 0.0
                : topCount / neighbours.length;

            return _QuestionRecommendationCard(
              question: q,
              ownAnswer: own,
              recommended: rec,
              confidence: confidence,
              counts: counts,
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget
{
  final int k;
  final List<TrainingUser> neighbours;
  final int totalVotes;

  const _HeaderCard({
    required this.k,
    required this.neighbours,
    required this.totalVotes,
  });

  @override
  Widget build(BuildContext context)
  {
    final String neighbourText = neighbours.isEmpty
        ? 'Keine'
        : neighbours.map((u) => u.userId).join(', ');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.recommend, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Übersicht',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.tune,
                  label: 'KNN (k=$k)',
                ),
                _InfoChip(
                  icon: Icons.group,
                  label: '${neighbours.length} ähnliche Nutzer',
                ),
                _InfoChip(
                  icon: Icons.how_to_vote,
                  label: '$totalVotes Votes gesamt',
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              'Top-${neighbours.length} ähnliche Nutzer: $neighbourText',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget
{
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context)
  {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _QuestionRecommendationCard extends StatelessWidget
{
  final Question question;
  final String? ownAnswer;
  final String? recommended;
  final double confidence;
  final Map<String, int> counts;

  const _QuestionRecommendationCard({
    required this.question,
    required this.ownAnswer,
    required this.recommended,
    required this.confidence,
    required this.counts,
  });

  @override
  Widget build(BuildContext context)
  {
    final String ownText = ownAnswer ?? '(keine)';
    final String recText = recommended ?? '–';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${question.id}: ${question.text}',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _LabeledValue(
                    label: 'Deine Antwort',
                    value: ownText,
                    icon: Icons.person,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledValue(
                    label: 'Empfehlung',
                    value: recText,
                    icon: Icons.star,
                    emphasize: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              'Confidence ${(confidence * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: confidence,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),

            const SizedBox(height: 14),

            Text(
              'Antwortverteilung (ähnliche Nutzer)',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),

            ...counts.entries.map((entry)
            {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(entry.key),
                    ),
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget
{
  final String label;
  final String value;
  final IconData icon;
  final bool emphasize;

  const _LabeledValue({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context)
  {
    final TextStyle? valueStyle = emphasize
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            )
        : Theme.of(context).textTheme.titleMedium;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: valueStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
