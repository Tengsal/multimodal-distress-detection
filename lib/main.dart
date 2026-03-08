import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/landing_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light(useMaterial3: true);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF111827), // Almost black
          primary: const Color(0xFF111827),
          surface: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: Color(0xFFE5E7EB), // Very subtle gray border
              width: 1,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF111827), // Sleek dark button
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100), // Fully pill-shaped for mobile feel
            ),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF111827),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        textTheme: base.textTheme.copyWith(
          headlineMedium: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
            color: Color(0xFF111827),
            height: 1.1,
          ),
          titleLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFF111827),
          ),
          titleMedium: const TextStyle(
            fontSize: 18,
            height: 1.4,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280), // Sleek gray
          ),
          bodyLarge: const TextStyle(
            fontSize: 17,
            height: 1.5,
            color: Color(0xFF4B5563),
          ),
          bodyMedium: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Color(0xFF6B7280),
          ),
          labelLarge: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const LandingScreen(),
    );
  }
}
