import 'package:flutter/material.dart';
import 'package:music/Screens/getstarted.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ggrhbczamauqdubwwbwi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdncmhiY3phbWF1cWR1Ynd3YndpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg4NzU0NzgsImV4cCI6MjA2NDQ1MTQ3OH0.j0bwnEeIEGj_ePQZosDHa3Q1HKm0BM00PaqruU0ImgM',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      
      home: const SplashScreen(),
    );
  }
}
