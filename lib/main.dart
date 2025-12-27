import 'package:flutter/material.dart';
import 'services/data_service.dart';
import 'models/question.dart';
import 'models/training_user.dart';
import 'screens/question_list_screen.dart';

void main() => runApp(const DecisionHelperApp());

class DecisionHelperApp extends StatelessWidget {
  const DecisionHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Decision Helper',
      theme: ThemeData(useMaterial3: true),
      home: const BootstrapScreen(),
    );
  }
}

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  final _dataService = DataService();
  late Future<(List<Question>, List<TrainingUser>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
  }

  Future<(List<Question>, List<TrainingUser>)> _loadAll() async {
    final questions = await _dataService.loadQuestions();
    final users = await _dataService.loadTrainingUsers();
    return (questions, users);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(List<Question>, List<TrainingUser>)>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Fehler: ${snapshot.error}')),
          );
        }

        final (questions, trainingUsers) = snapshot.data!;
        return QuestionListScreen(
          questions: questions,
          trainingUsers: trainingUsers,
        );
      },
    );
  }
}
