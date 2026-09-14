import 'package:flutter/material.dart';

import 'core/auth/servicio_auth.dart';
import 'core/cuenta/estado_cuenta.dart';
import 'core/auth/supabase_auth.dart';
import 'core/entorno.dart';
import 'features/auth/auth_gate.dart';
import 'theme/app_theme.dart';
import 'widgets/ocultar_teclado.dart';
import 'widgets/pantalla_carga.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Arranque());
}

/// Muestra la marca mientras se inicializa Supabase y luego entrega la app.
class Arranque extends StatefulWidget {
  const Arranque({super.key});

  @override
  State<Arranque> createState() => _ArranqueState();
}

class _ArranqueState extends State<Arranque> {
  // Sin espera artificial: el splash nativo y [PantallaCarga] dibujan lo mismo
  // en el mismo lugar, así que no hay parpadeo que disimular y la app abre lo
  // más rápido que pueda.
  late final Future<ServicioAuth> _inicio = SupabaseAuth.inicializar();

  @override
  Widget build(BuildContext context) {
    if (!Entorno.configurado) return const _AppSinConfigurar();

    return FutureBuilder<ServicioAuth>(
      future: _inicio,
      builder: (context, snapshot) {
        if (snapshot.hasData) return CmrApp(auth: snapshot.data!);

        return MaterialApp(
          title: 'CMR',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          builder: (context, child) => OcultarTeclado(child: child!),
          home: snapshot.hasError
              ? const _FalloDeArranque()
              : const PantallaCarga(),
        );
      },
    );
  }
}

class CmrApp extends StatelessWidget {
  const CmrApp({super.key, required this.auth, this.cuenta});

  final ServicioAuth auth;

  /// De donde se lee si la cuenta esta aprobada. En la app sale de Supabase;
  /// los tests inyectan una fuente falsa.
  final FuenteCuenta? cuenta;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CMR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // El logo todavía no tiene versión para fondo oscuro, así que la app
      // se mantiene en claro hasta que exista ese arte.
      themeMode: ThemeMode.light,
      builder: (context, child) => OcultarTeclado(child: child!),
      home: AuthGate(auth: auth, cuenta: cuenta),
    );
  }
}

/// Se muestra cuando falta SUPABASE_PUBLISHABLE_KEY. Sin esto la app
/// reventaría en el arranque con un error que no dice qué hacer.
class _AppSinConfigurar extends StatelessWidget {
  const _AppSinConfigurar();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CMR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) => OcultarTeclado(child: child!),
      home: const _Aviso(
        icono: Icons.key_off_outlined,
        titulo: 'Falta la clave de Supabase',
        detalle:
            'Copia config/supabase.example.json a config/supabase.json, '
            'pon la clave publicable del proyecto y compila con:\n\n'
            'flutter run --dart-define-from-file=config/supabase.json',
      ),
    );
  }
}

/// Supabase no arrancó: sin sesión posible, no tiene sentido seguir.
class _FalloDeArranque extends StatelessWidget {
  const _FalloDeArranque();

  @override
  Widget build(BuildContext context) {
    return const _Aviso(
      icono: Icons.cloud_off_outlined,
      titulo: 'No pudimos iniciar la app',
      detalle: 'Revisa tu conexión a internet y vuelve a abrirla.',
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 56, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 20),
              Text(
                titulo,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(detalle, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
