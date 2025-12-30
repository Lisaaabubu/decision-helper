import 'dart:math';

import '../models/question.dart';
import '../models/training_user.dart';

class RecommenderService
{
  /// Explizite Kodierung einer Antwort
  /// Gibt den Index der Antwortoption zurück (0..n-1)
  /// oder 0, falls die Antwort nicht gefunden wird.
  int encodeAnswer(
    String questionId,
    String answer,
    List<Question> questions,
  )
  {
    final question = questions.firstWhere(
      (q) => q.id == questionId,
      orElse: () => throw Exception('Unknown questionId: $questionId'),
    );

    final index = question.options.indexOf(answer);

    if (index < 0)
    {
      return 0;
    }

    // WICHTIG: +1, damit echte Antworten niemals 0 sind
    return index + 1;

  }

  /// Schritt 1: Nutzerantworten → Zahlenvektor
  List<int> vectorizeAnswers(
    Map<String, String> answers,
    List<Question> questions,
  )
  {
    return questions.map((q)
    {
      final answer = answers[q.id];

      if (answer == null)
      {
        return 0;
      }

      return encodeAnswer(q.id, answer, questions);
    }).toList();
  }

  /// Baut eine Maske, welche Fragen bereits beantwortet wurden
  List<bool> buildAnsweredMask(
    Map<String, String> currentAnswers,
    List<Question> questions,
  )
  {
    return questions.map((q)
    {
      return currentAnswers.containsKey(q.id);
    }).toList();
  }

  /// Cosine Similarity, ignoriert unbeantwortete Dimensionen
  double cosineSimilarityMasked(
    List<int> a,
    List<int> b,
    List<bool> mask,
  )
  {
    double dot = 0;
    double magA = 0;
    double magB = 0;

    for (int i = 0; i < a.length; i++)
    {
      if (!mask[i])
      {
        continue;
      }

      dot += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }

    if (magA == 0 || magB == 0)
    {
      return 0.0;
    }

    return dot / (sqrt(magA) * sqrt(magB));
  }

  /// Schritt 3: KNN – ähnlichste Nutzer finden
  List<TrainingUser> findNearestNeighbours({
    required Map<String, String> currentAnswers,
    required List<TrainingUser> trainingUsers,
    required List<Question> questions,
    int k = 3,
  })
  {
    final currentVector = vectorizeAnswers(currentAnswers, questions);
    final mask = buildAnsweredMask(currentAnswers, questions);

    final scored = trainingUsers.map((user)
    {
      final vector = vectorizeAnswers(user.answers, questions);
      final similarity = cosineSimilarityMasked(
        currentVector,
        vector,
        mask,
      );

      return MapEntry(user, similarity);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.take(k).map((e) => e.key).toList();
  }

  /// Schritt 4: Häufigkeiten für Empfehlungen berechnen
  Map<String, Map<String, int>> calculateFrequencies(
    List<TrainingUser> neighbours,
    List<Question> questions,
  )
  {
    final result = <String, Map<String, int>>{};

    for (final q in questions)
    {
      final counts = <String, int>{};

      for (final u in neighbours)
      {
        final answer = u.answers[q.id];

        if (answer != null)
        {
          counts[answer] = (counts[answer] ?? 0) + 1;
        }
      }

      result[q.id] = counts;
    }

    return result;
  }

  /// Anzahl der Trainingsvotes pro Frage
  int totalVotesForQuestion(
    String questionId,
    List<TrainingUser> trainingUsers,
  )
  {
    int total = 0;

    for (final u in trainingUsers)
    {
      if (u.answers.containsKey(questionId))
      {
        total++;
      }
    }

    return total;
  }
}
