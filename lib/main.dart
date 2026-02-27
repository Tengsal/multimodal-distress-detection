import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/session_provider.dart';
import 'screens/interview_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionProvider(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: InterviewScreen(),
      ),
    );
  }
}