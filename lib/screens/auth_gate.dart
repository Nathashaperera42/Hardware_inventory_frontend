import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/auth_session.dart';
import '../widgets/login_dialog.dart';
import 'home_shell.dart';

/// Blocks the app behind an admin login popup until [AuthSession] holds a token.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    AuthSession.instance.addListener(_onAuthChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowLogin());
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {});
    _maybeShowLogin();
  }

  void _maybeShowLogin() {
    if (_dialogShowing || AuthSession.instance.isLoggedIn) return;
    _dialogShowing = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoginDialog(),
    ).then((_) => _dialogShowing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthSession.instance.isLoggedIn) {
      return const Scaffold(backgroundColor: AppColors.scaffold);
    }
    return const HomeShell();
  }
}
