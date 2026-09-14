import 'package:flutter/material.dart';

import '../../core/auth/servicio_auth.dart';
import '../../widgets/cmr_logo.dart';
import '../cuenta/mi_cuenta_screen.dart';

/// Por qué esta cuenta no está viendo la app.
enum MotivoEspera {
  /// Se registró y el doctor todavía no la revisa.
  pendiente,

  /// El doctor la dio de baja.
  dadaDeBaja,

  /// No se pudo comprobar, casi siempre porque no hay red.
  sinConfirmar,
}

/// Lo que ve quien tiene sesión pero todavía no es paciente aprobado.
///
/// No es una pantalla de error: es la mayoría de los casos el estado normal de
/// alguien que acaba de registrarse. Por eso explica qué sigue y quién tiene
/// que hacerlo, en vez de disculparse.
class EsperandoAprobacionScreen extends StatelessWidget {
  const EsperandoAprobacionScreen({
    super.key,
    required this.auth,
    required this.motivo,
    required this.onReintentar,
    this.mensaje,
  });

  final ServicioAuth auth;
  final MotivoEspera motivo;
  final VoidCallback onReintentar;

  /// Detalle de la falla, solo para [MotivoEspera.sinConfirmar].
  final String? mensaje;

  ({IconData icono, String titulo, String texto}) get _contenido =>
      switch (motivo) {
        MotivoEspera.pendiente => (
          icono: Icons.hourglass_empty,
          titulo: 'Tu cuenta está en revisión',
          texto:
              'La clínica tiene que confirmar que sos paciente antes de '
              'abrirte la app. Suele ser cosa de horas. Te avisamos apenas '
              'esté lista.',
        ),
        MotivoEspera.dadaDeBaja => (
          icono: Icons.pause_circle_outline,
          titulo: 'Tu cuenta está dada de baja',
          texto:
              'La clínica desactivó esta cuenta. Si creés que es un error, '
              'consultá en recepción.',
        ),
        MotivoEspera.sinConfirmar => (
          icono: Icons.cloud_off_outlined,
          titulo: 'No pudimos verificar tu cuenta',
          texto: mensaje ?? 'Revisa tu conexión a internet y volvé a intentar.',
        ),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = _contenido;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CmrLogo(alto: 72),
                  const SizedBox(height: 36),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(c.icono, size: 32, color: scheme.primary),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    c.titulo,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    c.texto,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (auth.correoActual case final correo?) ...[
                    const SizedBox(height: 20),
                    Text(
                      correo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: onReintentar,
                    child: const Text('Volver a revisar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MiCuentaScreen(auth: auth),
                      ),
                    ),
                    child: const Text('Mi cuenta'),
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
