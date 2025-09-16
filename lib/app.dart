import 'package:flutter/material.dart';

import 'auth/auth_gate.dart';

class MealPrepApp extends StatelessWidget {
  const MealPrepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meal Prep Plan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F855A)),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
