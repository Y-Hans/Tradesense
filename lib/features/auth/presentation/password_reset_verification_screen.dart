import 'package:flutter/material.dart';
import 'package:cryptoedu/shared/widgets/crypto_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';

class PasswordResetVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  const PasswordResetVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<PasswordResetVerificationScreen> createState() => _PasswordResetVerificationScreenState();
}

class _PasswordResetVerificationScreenState extends ConsumerState<PasswordResetVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authStateProvider.notifier).verifyOTP(
          email: widget.email,
          token: _tokenController.text,
          type: 'recovery',
        );

    if (mounted) {
      if (success) {
        context.go('/set-new-password');
      } else {
        final errorMsg = ref.read(authStateProvider).errorMessage ?? 'Verification failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isAuthenticating;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter the reset code sent to your email address.'),
              const SizedBox(height: 24),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(labelText: 'OTP Token'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter the token.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleVerify,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CryptoLoadingIndicator(size: 30),
                        )
                      : const Text('VERIFY OTP'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final ok = await ref
                              .read(authStateProvider.notifier)
                              .resendOTP(email: widget.email, type: 'recovery');
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'A new recovery code was sent.'
                                  : (ref.read(authStateProvider).errorMessage ??
                                      'Unable to resend the code.')),
                            ),
                          );
                        },
                  child: const Text('RESEND CODE'),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: isLoading ? null : () => context.go('/login'),
                  child: const Text("Back to Login"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
