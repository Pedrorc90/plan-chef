import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onSwitchToSignUp});
  final VoidCallback? onSwitchToSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String error = '';
  bool isLoading = false;

  Future<void> signIn() async {
    setState(() {
      isLoading = true;
      error = '';
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = e.message ?? 'Error';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red)),
            if (isLoading) const CircularProgressIndicator(),
            if (!isLoading) ...[
              ElevatedButton(
                onPressed: signIn,
                child: const Text('Entrar'),
              ),
              TextButton(
                onPressed: widget.onSwitchToSignUp,
                child: const Text('Crear cuenta nueva'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
