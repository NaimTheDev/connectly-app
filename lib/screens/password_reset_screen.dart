import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../services/auth_exceptions.dart';
import '../widgets/auth_error_widgets.dart';
import '../theme/theme.dart';
import '../widgets/spacers.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _emailSent = false;
  AuthException? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final authService = ref.read(authServiceProvider);

    try {
      await authService.sendPasswordResetEmail(_emailController.text.trim());
      setState(() {
        _error = null;
        _emailSent = true;
      });
    } on AuthException catch (e) {
      setState(() => _error = e);
    } catch (e) {
      setState(() => _error = UnknownAuthException(e.toString()));
    } finally {
      setState(() => _loading = false);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Spacers.h32,
                // Header illustration/icon
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: brand.brand.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _emailSent ? Icons.mark_email_read : Icons.lock_reset,
                    size: 40,
                    color: brand.brand,
                  ),
                ),

                // Title and description
                Text(
                  _emailSent ? 'Check Your Email' : 'Reset Your Password',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: brand.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                Spacers.h16,
                Text(
                  _emailSent
                      ? 'We\'ve sent password reset instructions to\n${_emailController.text.trim()}'
                      : 'Enter your email address and we\'ll send you a link to reset your password.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: brand.graphite,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                Spacers.h40,

                if (!_emailSent) ...[
                  // Email input field
                  TextFormField(
                    controller: _emailController,
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _sendPasswordResetEmail(),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: brand.brand,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(brand.radius),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(brand.radius),
                        borderSide: BorderSide(color: brand.brand, width: 2),
                      ),
                    ),
                  ),
                  Spacers.h24,

                  // Error display
                  if (_error != null)
                    AuthErrorCard(
                      error: _error!,
                      onRetry: () {
                        setState(() => _error = null);
                        _sendPasswordResetEmail();
                      },
                      onDismiss: () => setState(() => _error = null),
                    ),

                  // Send reset email button
                  ElevatedButton(
                    onPressed: _loading ? null : _sendPasswordResetEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand.brand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(brand.radius),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Send Reset Email',
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ] else ...[
                  // Success state - email sent
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(brand.radius),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 24,
                        ),
                        Spacers.w12,
                        Expanded(
                          child: Text(
                            'Password reset email sent successfully!',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacers.h24,

                  // Resend email button
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _emailSent = false;
                        _error = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: brand.brand),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(brand.radius),
                      ),
                    ),
                    child: Text(
                      'Send Another Email',
                      style: textTheme.labelLarge?.copyWith(
                        color: brand.brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Back to sign in
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: 18, color: brand.brand),
                      Spacers.w8,
                      Text(
                        'Back to Sign In',
                        style: TextStyle(
                          color: brand.brand,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacers.h16,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
