import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isLoading = false;
  String errorMessage = '';
  String successMessage = '';

  Future<void> updatePassword() async {
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      setState(() {
        errorMessage = 'Completa ambos campos.';
        successMessage = '';
      });
      return;
    }

    if (password != confirm) {
      setState(() {
        errorMessage = 'Las contraseñas no coinciden.';
        successMessage = '';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        errorMessage = 'La contraseña debe tener al menos 6 caracteres.';
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
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (!mounted) return;

      setState(() {
        successMessage = 'Contraseña actualizada correctamente.';
        errorMessage = '';
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      context.go('/auth');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'No se pudo actualizar la contraseña. Solicita un nuevo enlace.';
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
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Card(
            color: AppTheme.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Nueva contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Crea una nueva contraseña para tu cuenta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar contraseña',
                    ),
                  ),
                  if (successMessage.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      successMessage,
                      style: const TextStyle(color: Colors.greenAccent),
                    ),
                  ],
                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: isLoading ? null : updatePassword,
                    child: Text(
                      isLoading ? 'Actualizando...' : 'Actualizar contraseña',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/auth'),
                    child: const Text('Volver al inicio de sesión'),
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
