import 'package:flutter/material.dart';
import '../models/question.dart';

class QuestionDetailScreen extends StatefulWidget {
  final Question question;
  final String? initialAnswer;

  const QuestionDetailScreen({
    super.key,
    required this.question,
    this.initialAnswer,
  });

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  String? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialAnswer;
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;

    return Scaffold(
      appBar: AppBar(title: Text(q.id)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.text, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...q.options.map((opt) {
              return RadioListTile<String>(
                title: Text(opt),
                value: opt,
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v),
              );
            }),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    selected == null ? null : () => Navigator.pop(context, selected),
                child: const Text('Speichern'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
