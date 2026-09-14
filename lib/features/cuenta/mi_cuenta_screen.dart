import 'package:flutter/material.dart';

import '../../core/auth/servicio_auth.dart';

/// Mi cuenta: el correo con que entra, cerrar sesión y eliminar la cuenta.
///
/// El borrado vive acá y no escondido en un submenú porque App Store y Google
/// Play piden que se pueda encontrar sin dar vueltas: si la app deja crear una
/// cuenta, tiene que dejar borrarla desde adentro.
class MiCuentaScreen extends StatefulWidget {
  const MiCuentaScreen({super.key, required this.auth});

  final ServicioAuth auth;

  @override
  State<MiCuentaScreen> createState() => _MiCuentaScreenState();
}

class _MiCuentaScreenState extends State<MiCuentaScreen> {
  bool _eliminando = false;

  Future<void> _salir() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('Vas a tener que volver a ingresar tus datos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (!(confirmado ?? false)) return;

    await widget.auth.salir();
    _volverAlPrincipio();
  }

  /// Saca esta pantalla de la pila al terminarse la sesión.
  ///
  /// El portón de arriba cambia a login solo, pero esta pantalla está *encima*
  /// de él: sin esto, quien cierra sesión se queda mirando "Mi cuenta" como si
  /// no hubiera pasado nada.
  void _volverAlPrincipio() {
    if (!mounted) return;
    Navigator.of(context).popUntil((ruta) => ruta.isFirst);
  }

  Future<void> _eliminar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar tu cuenta?'),
        content: const Text(
          'Se borra todo y no se puede deshacer: tu plan, tus citas, tus '
          'laboratorios, tus mediciones, lo que te recetaron y lo que '
          'anotaste en el mapeo.\n\n'
          'Si querés volver a usar la app vas a tener que registrarte de '
          'nuevo y esperar a que la clínica te apruebe otra vez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (!(confirmado ?? false)) return;

    setState(() => _eliminando = true);
    try {
      await widget.auth.eliminarCuenta();
      _volverAlPrincipio();
      // Si esta pantalla era la primera de la pila, no hubo a dónde volver y
      // sigue montada: sin esto quedaría con el spinner girando.
      if (mounted) setState(() => _eliminando = false);
    } on FallaAuth catch (e) {
      if (!mounted) return;
      setState(() => _eliminando = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(e.mensaje),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.mail_outline, color: scheme.primary),
              title: const Text('Correo'),
              subtitle: Text(widget.auth.correoActual ?? '—'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.logout, color: scheme.primary),
              title: const Text('Cerrar sesión'),
              onTap: _eliminando ? null : _salir,
            ),
          ),

          const SizedBox(height: 32),
          Text('Eliminar la cuenta', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Borra tu cuenta y todo lo que hay en ella. No se puede deshacer.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _eliminando ? null : _eliminar,
            icon: _eliminando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            label: Text(_eliminando ? 'Eliminando…' : 'Eliminar mi cuenta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
