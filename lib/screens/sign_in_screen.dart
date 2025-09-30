import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../services/auth_exceptions.dart';
import '../widgets/auth_error_widgets.dart';
import 'onboarding/onboarding_flow_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  AuthException? _error;

  Future<void> _signInWithEmail() async {
    setState(() => _loading = true);
    final authService = ref.read(authServiceProvider);
    try {
      await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      setState(() => _error = null);
    } on AuthException catch (e) {
      setState(() => _error = e);
    } catch (e) {
      setState(() => _error = UnknownAuthException(e.toString()));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    final authService = ref.read(authServiceProvider);
    try {
      final (user, isNew) = await authService.signInWithGoogle();
      setState(() => _error = null);
      if (mounted && isNew && user != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingFlowScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = e);
    } catch (e) {
      setState(() => _error = UnknownAuthException(e.toString()));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              if (_error != null)
                AuthErrorCard(
                  error: _error!,
                  onRetry: () {
                    setState(() => _error = null);
                    if (_emailController.text.isNotEmpty &&
                        _passwordController.text.isNotEmpty) {
                      _signInWithEmail();
                    }
                  },
                  onDismiss: () => setState(() => _error = null),
                ),
              ElevatedButton(
                onPressed: _loading ? null : _signInWithEmail,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Sign In'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Sign In with Google'),
                onPressed: _loading ? null : _signInWithGoogle,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/password-reset');
                },
                child: const Text('Forgot Password?'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: const Text('Don\'t have an account? Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
