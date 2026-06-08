import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  String errorMessage = '';
  String successMessage = '';

  AppLocalizations get l10n => AppLocalizations.of(context);

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = l10n.completeEmailAndPassword;
        successMessage = '';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
      successMessage = '';
    });

    try {
      if (isLogin) {
        await AuthService.signIn(
          email: email,
          password: password,
        );

        try {
          await const SubscriptionService().syncCurrentUserPlan();
        } catch (syncError) {
          debugPrint('No se pudo sincronizar el plan del usuario: $syncError');
        }

        if (!mounted) return;

        context.go('/dashboard');
      } else {
        await AuthService.signUp(
          email: email,
          password: password,
        );

        if (!mounted) return;

        setState(() {
          isLogin = true;
          successMessage =
              'Cuenta creada correctamente. Revisa tu correo electrónico para confirmar tu cuenta antes de iniciar sesión.';
          errorMessage = '';
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = AuthService.friendlyAuthError(error);
        successMessage = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> sendPasswordReset() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        errorMessage =
            'Escribe tu correo electrónico para enviarte el enlace de recuperación.';
        successMessage = '';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
      successMessage = '';
    });

    try {
      await AuthService.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      setState(() {
        successMessage =
            'Te enviamos un enlace para restablecer tu contraseña. Revisa tu correo electrónico.';
        errorMessage = '';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = AuthService.friendlyAuthError(error);
        successMessage = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> resendConfirmationEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage =
            'Escribe tu correo y contraseña para reenviar el correo de confirmación.';
        successMessage = '';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
      successMessage = '';
    });

    try {
      await AuthService.resendSignupConfirmation(
        email: email,
        password: password,
      );

      if (!mounted) return;

      setState(() {
        successMessage =
            'Si tu cuenta aún no está confirmada, te enviamos un nuevo correo de confirmación. Revisa tu bandeja de entrada o spam.';
        errorMessage = '';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = AuthService.friendlyAuthError(error);
        successMessage = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 430,
          ),
          child: Card(
            color: AppTheme.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'StudyBook AI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLogin ? l10n.loginSubtitle : l10n.signupSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.passwordLabel,
                    ),
                  ),
                  if (successMessage.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      successMessage,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      errorMessage,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isLogin
                                ? l10n.loginButton
                                : l10n.createAccountButton,
                          ),
                  ),
                  if (isLogin) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: isLoading ? null : sendPasswordReset,
                      icon: const Icon(Icons.lock_reset_rounded, size: 18),
                      label: const Text('¿Olvidaste tu contraseña?'),
                    ),
                    TextButton.icon(
                      onPressed: isLoading ? null : resendConfirmationEmail,
                      icon: const Icon(Icons.mark_email_read_rounded, size: 18),
                      label: const Text('Reenviar correo de confirmación'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              isLogin = !isLogin;
                              errorMessage = '';
                              successMessage = '';
                            });
                          },
                    child: Text(
                      isLogin
                          ? l10n.createAccountLink
                          : l10n.alreadyHaveAccount,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
