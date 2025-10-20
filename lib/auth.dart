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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 64,
                  color: Color(0xFF6C63FF),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to DingDong',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF2D3142),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin ? 'Log in to continue' : 'Create your account',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
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
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            setState(() => isLoading = true);

                            final email = _email.text.trim();
                            final password = _password.text;

                            if (email.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill in all fields'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setState(() => isLoading = false);
                              return;
                            }

                            try {
                              if (isLogin) {
                                final response = await supabase.auth.signInWithPassword(
                                  email: email,
                                  password: password,
                                );
                                
                                if (response.user != null) {
                                  if (!mounted) return;
                                  await Navigator.pushReplacement(
                                    context, 
                                    MaterialPageRoute(builder: (_) => const NotesPage())
                                  );
                                }
                              } else {
                                if (password.length < 6) {
                                  throw Exception('Password must be at least 6 characters');
                                }

                                final response = await supabase.auth.signUp(
                                  email: email,
                                  password: password,
                                  data: {
                                    'email': email,
                                  },
                                );

                                if (response.user != null) {
                                  try {
                                    await supabase.from('users').insert({
                                      'user_id': response.user!.id,
                                      'email': email,
                                      'image_url': '',
                                      'created_at': DateTime.now().toIso8601String(),
                                    }).select();
                                    
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Registration successful! You can now log in.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    setState(() => isLogin = true);
                                  } catch (profileError) {
                                    print('Error creating profile: $profileError');
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Account created but profile setup incomplete. Please try logging in.'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    setState(() => isLogin = true);
                                  }
                                } else {
                                  throw Exception('Failed to create user account');
                                }
                              }
                            } catch (e) {
                              if (!mounted) return;
                              
                              String errorMessage;
                              IconData errorIcon;
                              
                              if (e.toString().contains('SocketException') || 
                                  e.toString().contains('Failed host lookup')) {
                                errorMessage = 'Network error. Please check your internet connection.';
                                errorIcon = Icons.wifi_off;
                              } else if (e.toString().contains('AuthException')) {
                                errorMessage = 'Invalid email or password';
                                errorIcon = Icons.error_outline;
                              } else if (e.toString().contains('already registered') || 
                                       e.toString().contains('already been taken')) {
                                errorMessage = 'This email is already registered';
                                errorIcon = Icons.person_off;
                              } else if (e.toString().contains('least 6 characters')) {
                                errorMessage = 'Password must be at least 6 characters';
                                errorIcon = Icons.lock_outline;
                              } else if (e.toString().contains('valid email')) {
                                errorMessage = 'Please enter a valid email address';
                                errorIcon = Icons.email_outlined;
                              } else {
                                errorMessage = 'An unexpected error occurred. Please try again.';
                                errorIcon = Icons.error_outline;
                                print('Auth Error: $e');
                              }
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(errorIcon, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(errorMessage)),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  action: SnackBarAction(
                                    label: 'Dismiss',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    },
                                  ),
                                ),
                              );
                            }

                            if (mounted) {
                              setState(() => isLoading = false);
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isLogin ? Icons.login : Icons.person_add),
                              const SizedBox(width: 8),
                              Text(title),
                            ],
                          ),
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
