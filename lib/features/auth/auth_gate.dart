import 'package:flutter/material.dart';

import '../../core/auth/servicio_auth.dart';
import '../../core/cuenta/estado_cuenta.dart';
import '../inicio/home_shell.dart';
import 'esperando_aprobacion_screen.dart';
import 'login_screen.dart';

/// Decide qué pantalla mostrar según haya sesión o no.
///
/// Supabase persiste la sesión y renueva el token solo, así que al reabrir la
/// app el usuario entra directo sin volver a ver el login.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.auth, this.cuenta});

  final ServicioAuth auth;

  /// De dónde se lee si la cuenta está aprobada. En la app sale de Supabase;
  /// los tests inyectan una fuente falsa.
  final FuenteCuenta? cuenta;

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
              ? _PortonDeCuenta(
                  // La llave lleva el correo para que al cambiar de cuenta se
                  // vuelva a consultar el estado en vez de reusar el anterior.
                  key: ValueKey('cuenta-${auth.correoActual}'),
                  auth: auth,
                  cuenta: cuenta,
                )
              : LoginScreen(key: const ValueKey('login'), auth: auth),
        );
      },
    );
  }
}

/// La segunda puerta: hay sesión, pero ¿el doctor aprobó esta cuenta?
///
/// Va acá y no dentro de cada módulo a propósito: si la comprobación viviera
/// pantalla por pantalla, una pantalla nueva se olvidaría de hacerla. Acá,
/// todo lo que cuelgue del Home queda cubierto por existir.
class _PortonDeCuenta extends StatefulWidget {
  const _PortonDeCuenta({super.key, required this.auth, required this.cuenta});

  final ServicioAuth auth;
  final FuenteCuenta? cuenta;

  @override
  State<_PortonDeCuenta> createState() => _PortonDeCuentaState();
}

class _PortonDeCuentaState extends State<_PortonDeCuenta> {
  late Future<EstadoCuenta> _carga = _cargar();

  Future<EstadoCuenta> _cargar() async {
    final fuente = widget.cuenta ?? RepositorioCuenta();
    return fuente.estado();
  }

  void _reintentar() {
    setState(() {
      _carga = _cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EstadoCuenta>(
      future: _carga,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Esperando();
        }

        if (snapshot.hasError) {
          // Sin poder comprobarlo, no se entra. Dejar pasar "por si acaso"
          // sería exactamente el agujero que la aprobación viene a tapar.
          return EsperandoAprobacionScreen(
            auth: widget.auth,
            motivo: MotivoEspera.sinConfirmar,
            mensaje: snapshot.error is FallaCuenta
                ? (snapshot.error! as FallaCuenta).mensaje
                : 'No pudimos verificar tu cuenta.',
            onReintentar: _reintentar,
          );
        }

        return switch (snapshot.data) {
          EstadoCuenta.activa => HomeShell(
            key: const ValueKey('home'),
            auth: widget.auth,
          ),
          EstadoCuenta.inactiva => EsperandoAprobacionScreen(
            auth: widget.auth,
            motivo: MotivoEspera.dadaDeBaja,
            onReintentar: _reintentar,
          ),
          _ => EsperandoAprobacionScreen(
            auth: widget.auth,
            motivo: MotivoEspera.pendiente,
            onReintentar: _reintentar,
          ),
        };
      },
    );
  }
}

class _Esperando extends StatelessWidget {
  const _Esperando();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
