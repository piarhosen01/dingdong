import 'package:dingdong/auth.dart';
import 'package:dingdong/notes.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://btspnfanrcbwgsnybfti.supabase.com',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ0c3BuZmFucmNid2dzbnliZnRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0MjYzODMsImV4cCI6MjA3NTAwMjM4M30.d59AbuErq5EUwQ9mXep19PYC0hWnzWmi4GwRBMJorK0',
  );
  
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
   MyApp({super.key});

  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DingDong',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: NotesPage(),
    );
  }
}
