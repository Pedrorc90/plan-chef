import 'package:flutter/material.dart';

import 'package:plan_chef/screens/auth/login_screen.dart';
import 'package:plan_chef/screens/auth/signup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool showSignUp = false;

  void switchToSignUp() => setState(() => showSignUp = true);
  void switchToLogin() => setState(() => showSignUp = false);

  @override
  Widget build(BuildContext context) {
    return showSignUp
        ? SignUpScreen(onSwitchToLogin: switchToLogin)
        : LoginScreen(onSwitchToSignUp: switchToSignUp);
  }
}
