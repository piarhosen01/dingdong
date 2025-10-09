import 'package:dingdong/auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => __NotesPagStateState();
}

class __NotesPagStateState extends State<NotesPage> {
  final supabase = Supabase.instance.client;
  late final Stream<List<Map<String, dynamic>>> _notesStream;

  @override
  void initState() {
    super.initState();
    final uid = supabase.auth.currentUser?.id;
    _notesStream = supabase
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq( 'user_id', uid = '1')
        .order('created_at', ascending: false);
  }

  Future<void> addNoteDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Add Note'),
        contentPadding: EdgeInsets.all(16),
        // ignore: sort_child_properties_last
        children: [
          TextFormField(
            controller: controller,
            autocorrect: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => Navigator.pop(context, controller.text),
            decoration: const InputDecoration(
              hintText: 'Type your note here...',
              border: OutlineInputBorder(),
            ),
          ), //

          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text("Save"),
          ),
        ],
      ),
    ).then((onValue) async {
      final body = (onValue as String?)?.trim();
      if (body == null || body.isEmpty) return;
      await supabase.from('notes').insert({
        'user_id': supabase.auth.currentUser?.id,
        'body': body,
      });
    });
  }

  Future<void> editNoteDialog(Map<String, dynamic> note) async {
    final controller = TextEditingController(
      text: note['body'] as String ?? '',
    );
    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Edit Note'),
        contentPadding: EdgeInsets.all(16),
        // ignore: sort_child_properties_last
        children: [
          TextFormField(
            controller: controller,
            autocorrect: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => Navigator.pop(context, controller.text),
            decoration: const InputDecoration(
              hintText: 'Type your note here...',
              border: OutlineInputBorder(),
            ),
          ), //

          const SizedBox(height: 12),

          Row(
            children: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: Text("Save"),
              ),
            ],
          ),
        ],
      ),
    ).then((onValue) async {
      final body = (onValue as String?)?.trim();
      if (body == null || body.isEmpty) return;
      await supabase
          .from('notes')
          .update({'body': body})
          .eq('id', note['id'] as int);
    });
  }

  Future<void> deleteNoteDialog(Map<String, dynamic> note) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete a Note'),
        content: const Text('Are you sure you want to delete this note?'),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await supabase.from('notes').delete().eq('id', note['id']);
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => AuthPage()),
      (Route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dingong Notes'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notes = snapshot.data!;
          if (notes.isEmpty) {
            return const Center(
              child: Text('No notes yet. Add note by clicking + button.'),
            );
          }
          return ListView.separated(
            itemCount: notes.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note['body'] as String? ?? ''),
                subtitle: Text(
                  (note['created_at'] as String?)?.toString() ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: Wrap(
                  spacing: 12,
                  children: [
                    IconButton(
                      onPressed: () => editNoteDialog(note),
                      icon: Icon(Icons.edit, color: Colors.blue),
                    ),
                    IconButton(
                      onPressed: () => deleteNoteDialog(note),
                      icon: Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
                onTap: () => editNoteDialog(note),
                onLongPress: () => deleteNoteDialog(note),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNoteDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
