import 'package:flutter/material.dart';

import '../../core/auth/servicio_auth.dart';
import '../inicio/home_shell.dart';
import 'login_screen.dart';

/// Decide qué pantalla mostrar según haya sesión o no.
///
/// Supabase persiste la sesión y renueva el token solo, así que al reabrir la
/// app el usuario entra directo sin volver a ver el login.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.auth});

  final ServicioAuth auth;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: auth.cambiosDeSesion,
      initialData: auth.autenticado,
      builder: (context, snapshot) {
        final autenticado = snapshot.data ?? false;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: autenticado
              ? HomeShell(key: const ValueKey('home'), auth: auth)
              : LoginScreen(key: const ValueKey('login'), auth: auth),
        );
      },
    );
  }
}
