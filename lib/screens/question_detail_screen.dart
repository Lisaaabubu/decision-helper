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

  void _onSelect(String qId, String? value)
  {
    setState(()
    {
      selected = value;

      if (value != null)
      {
        _previewAnswers[qId] = value;
      }
      else
      {
        _previewAnswers.remove(qId);
      }

      // Wenn die Hauptantwort geändert wird, Why-Auswahl ggf. zurücksetzen
      selectedWhy = null;
    });
  }

  @override
  Widget build(BuildContext context)
  {
    final Question q = widget.question;
    final String qId = q.id;

    final bool isQ1 = qId == "Q1";
    final bool isQ4 = qId == "Q4";

    final bool showHelperCard = isQ1
        ? selected != null
        : true;

    final bool hasWhyOptions = whyOptionsPerQuestion.containsKey(qId);
    final bool showWhyBlock = hasWhyOptions && selected != null;

    final List<TrainingUser> neighbours = _recommender.findNearestNeighbours(
      currentAnswers: widget.currentAnswers,
      trainingUsers: widget.trainingUsers,
      questions: widget.questions,
      k: widget.k,
    );

    final Map<String, Map<String, int>> freqs = _recommender.calculateFrequencies(
      neighbours,
      [q],
    );

    final Map<String, int> rawCounts = freqs[qId] ?? {};

    final Map<String, int> counts =
    {
      for (final opt in q.options) opt: (rawCounts[opt] ?? 0),
    };

    final Map<String, int> overallCounts =
    {
      for (final opt in q.options) opt: 0,
    };

    for (final user in widget.trainingUsers)
    {
      final String? a = user.answers[qId];
      if (a != null && overallCounts.containsKey(a))
      {
        overallCounts[a] = (overallCounts[a] ?? 0) + 1;
      }
    }

    String? recommended;
    int topCount = 0;

    if (rawCounts.isNotEmpty)
    {
      final sorted = rawCounts.entries.toList()
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

    final String mainLabel = isQ1
        ? 'Häufigste Antwort (ähnliche Nutzer:innen)'
        : 'Empfehlung';

    final String mainValue = recommended ?? '–';

    return Scaffold(
      appBar: AppBar(
        title: Text(q.id),
      ),

      // ✅ FIX: Body ist nur noch scrollbar; Button sitzt fix unten
      body: SafeArea(
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
                if (isQ4)
                {
                  final String? iconPath = ideIconByOption[opt];

                  return RadioListTile<String>(
                    value: opt,
                    groupValue: selected,
                    onChanged: (v) => _onSelect(qId, v),
                    title: Row(
                      children: [
                        if (iconPath != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              iconPath,
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                            ),
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
                  onChanged: (v) => _onSelect(qId, v),
                );
              }).toList(),

              if (showHelperCard) ...[
                const SizedBox(height: 12),
                _DecisionHelperCard(
                  k: widget.k,
                  votesTotal: votesTotal,
                  neighbours: neighbours,
                  label: mainLabel,
                  value: mainValue,
                  confidence: confidence,
                  counts: counts,
                  overallCounts: overallCounts,
                ),
              ],

              if (showWhyBlock) ...[
                const SizedBox(height: 16),
                _WhyCard(
                  title: 'Warum hast du dich dafür entschieden?',
                  reasons: whyOptionsPerQuestion[qId]!,
                  selectedWhy: selectedWhy,
                  onChanged: (v)
                  {
                    setState(()
                    {
                      selectedWhy = v;
                    });
                  },
                ),
              ],

              // ✅ Damit der letzte Inhalt nicht unter dem Bottom-Button „verschwindet“
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),

      // ✅ FIX: Button fix unten, unabhängig von Scroll
      bottomNavigationBar: SafeArea(
        child: Padding(
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
      ),
    );
  }
}

class _DecisionHelperCard extends StatelessWidget
{
  final int k;
  final int votesTotal;
  final List<TrainingUser> neighbours;

  final String label;
  final String value;

  final double confidence;
  final Map<String, int> counts;
  final Map<String, int> overallCounts;

  const _DecisionHelperCard({
    required this.k,
    required this.votesTotal,
    required this.neighbours,
    required this.label,
    required this.value,
    required this.confidence,
    required this.counts,
    required this.overallCounts,
  });

  @override
  Widget build(BuildContext context)
  {
    final String neighbourText = neighbours.isEmpty
        ? 'Keine'
        : neighbours.map((u) => u.userId).join(', ');

    return Card(
      elevation: 3,
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
                const Icon(Icons.auto_graph, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Entscheidungshilfe',
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
                  icon: Icons.how_to_vote,
                  label: '$votesTotal Votes',
                ),
                _InfoChip(
                  icon: Icons.group,
                  label: '${neighbours.length} ähnlich',
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              'Ähnliche Nutzer: $neighbourText',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 16),

            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),

            const SizedBox(height: 16),

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

            const SizedBox(height: 16),

            Text(
              'Antwortverteilung (Top-k ähnliche Nutzer)',
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

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            Text(
              'Antwortverteilung (gesamt)',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),

            ...overallCounts.entries.map((entry)
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

class _WhyCard extends StatelessWidget
{
  final String title;
  final List<String> reasons;
  final String? selectedWhy;
  final ValueChanged<String?> onChanged;

  const _WhyCard({
    required this.title,
    required this.reasons,
    required this.selectedWhy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context)
  {
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
                const Icon(Icons.question_answer, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),

            const SizedBox(height: 10),

            ...reasons.map((reason)
            {
              return RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: selectedWhy,
                onChanged: onChanged,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
