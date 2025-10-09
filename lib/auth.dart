import 'package:dingdong/notes.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool isLogin = true;
  bool isLoading = false;
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = isLogin ? 'Login' : 'Signup';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Enter your Email here...',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  decoration: const InputDecoration(
                    labelText: 'Enter your Password here...',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            setState(() => isLoading = true);

                            final email = _email.text.trim();
                            final password = _password.text;

                            try {
                              if (isLogin) {
                                await supabase.auth.signInWithPassword(
                                  email: email,
                                  password: password,
                                );
                                if(!mounted) return;
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => NotesPage()));
                              } else {
                                final res = await supabase.auth.signUp(
                                  email: email,
                                  password: password,
                                );

                                if (res.user != null) {
                                  await supabase.from('users').insert({
                                    'user_id': res.user!.id,
                                    'email': email,
                                    'image_url': '',
                                  });
                                }
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }

                            setState(() => isLoading = false);
                          },
                    child: Text(title),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() => isLogin = !isLogin);
                        },
                  child: Text(
                    isLogin ? 'Create an account' : 'I have an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
