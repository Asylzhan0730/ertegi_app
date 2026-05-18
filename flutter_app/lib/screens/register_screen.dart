import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  String ageCategory = '5+';
  bool loading = false;

  Future<void> register() async {
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showError('Email және password енгізіңіз');
      return;
    }

    if (password.length < 4) {
      showError('Password кемінде 4 символ болсын');
      return;
    }

    setState(() => loading = true);

    try {
      final data = await ApiService.register(
        email: email,
        password: password,
        ageCategory: ageCategory,
      );

      await AuthStorage.saveAuth(
        token: data['token'],
        email: data['email'],
        ageCategory: data['ageCategory'] ?? ageCategory,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      showError(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> signUpWithGoogle() async {
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

      await AuthStorage.saveAuth(
        token: await user.getIdToken() ?? '',
        email: user.email!,
        ageCategory: ageCategory,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      showError('Google register error: $e');
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
    final ages = ['1-2', '3-4', '5+'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тіркелу'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Icon(
                Icons.person_add,
                size: 70,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 18),
              const Text(
                'Аккаунт ашу',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Жас тобы:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ages.map((item) {
                  return ChoiceChip(
                    label: Text(item),
                    selected: ageCategory == item,
                    onSelected: loading
                        ? null
                        : (_) {
                      setState(() {
                        ageCategory = item;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: loading ? null : register,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text('Тіркелу'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : signUpWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text('Google арқылы тіркелу'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}