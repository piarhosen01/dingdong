import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dingdong/auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  final _usernameController = TextEditingController();
  bool _loading = false;
  String? _imageUrl;
  String? _username;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      final userEmail = _supabase.auth.currentUser?.email;
      if (userId == null) throw Exception('Not authenticated');

      final data = await _supabase.from('users').select().eq('user_id', userId).single();
      String? imageUrl = data['image_url'] as String?;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        final parsed = Uri.tryParse(imageUrl);
        if (parsed != null && parsed.isAbsolute && (parsed.scheme == 'http' || parsed.scheme == 'https')) {
        } else {
          try {
            final public = _supabase.storage.from('avatars').getPublicUrl(imageUrl);
            final pu = Uri.tryParse(public);
            if (pu != null && pu.isAbsolute) {
              imageUrl = public;
            } else {
              final signed = await _supabase.storage.from('avatars').createSignedUrl(imageUrl, 60 * 60);
              final su = Uri.tryParse(signed);
              if (su != null && su.isAbsolute) {
                imageUrl = signed;
              } else {
                imageUrl = null;
              }
            }
          } catch (e) {
            imageUrl = null;
          }
        }
      } else {
        imageUrl = null;
      }

      setState(() {
        _email = userEmail;
        _imageUrl = imageUrl;
        _username = data['user_name'] as String? ?? userEmail?.split('@')[0] ?? 'User';
        _usernameController.text = _username!;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _supabase.from('users').update({'user_name': _usernameController.text.trim()}).eq('user_id', userId);

      if (mounted) {
        setState(() {
          _username = _usernameController.text.trim();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _uploadImage() async {
    setState(() {
      _loading = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 300, maxHeight: 300);
      if (image == null) return;

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'gif'].contains(fileExt)) {
        throw Exception('Invalid image format. Please use JPG, PNG or GIF.');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final imagePath = '$userId/$fileName';

      await _supabase.storage.from('avatars').uploadBinary(
            imagePath,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$fileExt', upsert: true),
          );

      String? finalUrl;
      try {
        final public = _supabase.storage.from('avatars').getPublicUrl(imagePath);
        final pu = Uri.tryParse(public);
        if (pu != null && pu.isAbsolute && (pu.scheme == 'http' || pu.scheme == 'https')) {
          finalUrl = public;
        }
      } catch (_) {}

      if (finalUrl == null) {
        try {
          final signed = await _supabase.storage.from('avatars').createSignedUrl(imagePath, 60 * 60);
          final su = Uri.tryParse(signed);
          if (su != null && su.isAbsolute) {
            finalUrl = signed;
          }
        } catch (_) {}
      }

      if (finalUrl == null || finalUrl.isEmpty) {
        throw Exception('Could not resolve a usable URL for the uploaded image');
      }

      await _supabase.from('users').update({'image_url': finalUrl}).eq('user_id', userId);

      setState(() {
        _imageUrl = finalUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile image: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Builder(
                          builder: (context) {
                            final validImageUrl = _imageUrl != null &&
                                _imageUrl!.isNotEmpty &&
                                _imageUrl!.startsWith('http');

                            if (validImageUrl) {
                              return CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: NetworkImage(_imageUrl!),
                                onBackgroundImageError: (exception, stackTrace) {
                                  if (mounted) {
                                    setState(() => _imageUrl = null);
                                  }
                                },
                              );
                            } else {
                              return CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade200,
                                child: const Icon(Icons.person, size: 50, color: Colors.grey),
                              );
                            }
                          },
                        ),
                        Positioned(
                          bottom: -10,
                          right: -10,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: _uploadImage,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(_email ?? '', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    child: const Text('Update Profile'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ],
              ),
            ),
    );
  }
}
