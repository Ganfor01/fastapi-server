import 'package:flutter/material.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  String? _message;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _friendlyAuthMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('invalid login credentials')) {
      return 'Ese correo o esa contraseña no son correctos.';
    }
    if (normalized.contains('user already registered')) {
      return 'Ya existe una cuenta con ese correo.';
    }
    if (normalized.contains('email not confirmed')) {
      return 'Necesitas confirmar tu correo antes de entrar.';
    }
    if (normalized.contains('password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (normalized.contains('signup is disabled')) {
      return 'Ahora mismo no se pueden crear cuentas nuevas.';
    }
    return 'No se pudo completar el acceso. Inténtalo de nuevo.';
  }

  String _friendlyGenericError(Object error) {
    final raw = error.toString().toLowerCase();
    if (error is ClientException ||
        raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('network') ||
        raw.contains('connection')) {
      return 'No se pudo conectar con el servicio. Revisa tu conexión e inténtalo de nuevo.';
    }
    if (raw.contains('certificate') || raw.contains('handshake')) {
      return 'No se pudo establecer una conexión segura con el servicio.';
    }
    return 'No se pudo completar el acceso. Inténtalo de nuevo.';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _message = 'Escribe un correo válido.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _message = 'La contraseña debe tener al menos 6 caracteres.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      if (_isSignUp) {
        final response = await _supabase.auth.signUp(
          email: email,
          password: password,
        );
        if (!mounted) {
          return;
        }
        if (response.session == null) {
          setState(() {
            _message = 'Cuenta creada. Ya puedes entrar con tus datos.';
          });
        }
      } else {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = _friendlyAuthMessage(error.message);
      });
    } catch (error) {
      debugPrint('Auth error: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _message = _friendlyGenericError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final isSuccess = _message != null && _message!.startsWith('Cuenta creada');

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2A3140)
                        : const Color(0xFFE6DED0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0x22000000)
                          : const Color(0x120F172A),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C2534)
                              : const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.lock_person_rounded,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _isSignUp ? 'Crear cuenta' : 'Entrar',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isSignUp
                            ? 'Empieza a organizar tu semana con tu propia cuenta.'
                            : 'Accede para ver tu planificación, tus hábitos y tus eventos.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isDark
                              ? const Color(0xFF98A2B3)
                              : const Color(0xFF667085),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          hintText: 'tu@email.com',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                        ),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _message!,
                          style: TextStyle(
                            color: isSuccess
                                ? const Color(0xFF1B7F4C)
                                : const Color(0xFFD64545),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : Text(_isSignUp ? 'Crear cuenta' : 'Entrar'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                    _message = null;
                                  });
                                },
                          child: Text(
                            _isSignUp
                                ? 'Ya tengo cuenta'
                                : 'Crear una cuenta nueva',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
