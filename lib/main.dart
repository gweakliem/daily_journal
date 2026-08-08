import 'package:flutter/material.dart';
import 'screens/journal_screen.dart';

void main() {
  runApp(const DailyJournalApp());
}

class DailyJournalApp extends StatelessWidget {
  const DailyJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Journal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const JournalScreen(),
    );
  }
}
