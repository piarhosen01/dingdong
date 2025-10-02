import 'package:flutter/material.dart';

class _NotesPagState extends StatefulWidget {
  const _NotesPagState({super.key});

  @override
  State<_NotesPagState> createState() => __NotesPagStateState();
}

class __NotesPagStateState extends State<_NotesPagState> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Notes Page'),
      ),
    );
  }
}