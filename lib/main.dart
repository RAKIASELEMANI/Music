import 'package:flutter/material.dart';
import 'package:music/Screens/getstarted.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vbexnxhdwiwygnunmazh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZiZXhueGhkd2l3eWdudW5tYXpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5NDk5MTUsImV4cCI6MjA2NDUyNTkxNX0.T4e2ET9Z7gDgzpJoeNi5oEqkZlQb1wrqe5IhMO2XAqA',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      
      home: const SplashScreen(),
    );
  }
}
