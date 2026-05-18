import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool loading = false;

  Future<void> login() async {
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showError('Email және password енгізіңіз');
      return;
    }

    setState(() => loading = true);

    try {
      final data = await ApiService.login(
        email: email,
        password: password,
      );

      await AuthStorage.saveAuth(
        token: data['token'],
        email: data['email'],
        ageCategory: data['ageCategory'] ?? '5+',
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    } catch (e) {
      showError(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      setState(() => loading = true);

      final provider = GoogleAuthProvider();
      final userCredential =
      await FirebaseAuth.instance.signInWithPopup(provider);

      final user = userCredential.user;

      if (user == null || user.email == null) {
        showError('Google аккаунт табылмады');
        return;
      }

      final data = await ApiService.googleLogin(
        email: user.email!,
        firebaseUid: user.uid,
        name: user.displayName,
      );

      await AuthStorage.saveAuth(
        token: data['token'],
        email: data['email'],
        ageCategory: data['ageCategory'] ?? '5+',
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    } catch (e) {
      showError('Google login error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Кіру'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Icon(
                Icons.auto_stories,
                size: 70,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 18),
              const Text(
                'Ертегі AI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: loading ? null : login,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text('Кіру'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text('Google арқылы кіру'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}