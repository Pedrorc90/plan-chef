import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.onSwitchToLogin});
  final VoidCallback? onSwitchToLogin;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String error = '';
  bool isLoading = false;

  Future<void> signUp() async {
    setState(() {
      isLoading = true;
      error = '';
    });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
      appBar: AppBar(title: const Text('Crear cuenta nueva')),
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
                onPressed: signUp,
                child: const Text('Crear cuenta'),
              ),
              TextButton(
                onPressed: widget.onSwitchToLogin,
                child: const Text('¿Ya tienes cuenta? Inicia sesión'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
