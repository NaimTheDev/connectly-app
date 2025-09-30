import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../models/app_user.dart';
import '../services/auth_exceptions.dart';
import '../widgets/auth_error_widgets.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole? _role;
  bool _loading = false;
  AuthException? _error;

  Future<void> _signUp() async {
    setState(() => _loading = true);
    final authService = ref.read(authServiceProvider);
    try {
      await authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _role!,
      );
      setState(() => _error = null);
      if (mounted) {
        // Let AuthGate handle routing based on onboarding status
        // Just pop back to let the auth state change trigger proper routing
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      setState(() => _error = e);
    } catch (e) {
      setState(() => _error = UnknownAuthException(e.toString()));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    if (_role == null) {
      setState(
        () => _error = const UnknownAuthException('Please select a role first'),
      );
      return;
    }

    setState(() => _loading = true);
    final authService = ref.read(authServiceProvider);
    try {
      await authService.signUpWithGoogle(_role!);
      setState(() => _error = null);
      if (mounted) {
        // Let AuthGate handle routing based on onboarding status
        // Just pop back to let the auth state change trigger proper routing
        Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Sign Up')),
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
              DropdownButtonFormField<UserRole>(
                value: _role,
                items: UserRole.values
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role.name)),
                    )
                    .toList(),
                onChanged: (role) => setState(() => _role = role),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              if (_error != null)
                AuthErrorCard(
                  error: _error!,
                  onRetry: () {
                    setState(() => _error = null);
                    if (_emailController.text.isNotEmpty &&
                        _passwordController.text.isNotEmpty &&
                        _role != null) {
                      _signUp();
                    }
                  },
                  onDismiss: () => setState(() => _error = null),
                ),
              ElevatedButton(
                onPressed: _loading || _role == null ? null : _signUp,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Sign Up'),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loading || _role == null ? null : _signUpWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Sign Up with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
