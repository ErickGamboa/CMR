import 'package:flutter/material.dart';

import '../core/datos/repositorio.dart';

/// Pide un dato a la base y dibuja lo que corresponda: espera, falla con
/// "Intentar de nuevo", o el contenido.
///
/// Está aparte porque las nueve pantallas que leen de Supabase hacen lo mismo,
/// y hacerlo a mano en cada una ya salió caro una vez: el `setState` que
/// devolvía un `Future` dejó el botón de reintentar roto en tres pantallas sin
/// que se notara.
class CargaDeDatos<T> extends StatefulWidget {
  const CargaDeDatos({
    super.key,
    required this.cargar,
    required this.constructor,
    this.vacio,
    this.estaVacio,
    this.alCargar,
    this.alFallar,
  });

  /// Se llama una sola vez al montar, y de nuevo en cada reintento.
  final Future<T> Function() cargar;

  final Widget Function(BuildContext context, T datos) constructor;

  /// Qué mostrar cuando no hay nada cargado todavía. Sin esto, el contenido
  /// se dibuja igual con la lista vacía.
  final Widget? vacio;

  /// Cuándo se considera vacío. Por defecto, una lista sin elementos.
  final bool Function(T datos)? estaVacio;

  /// Qué dibujar mientras carga. Por defecto, un indicador centrado.
  final Widget? alCargar;

  /// Qué dibujar si falla. Por defecto, el aviso con "Intentar de nuevo".
  ///
  /// El Home lo pone en blanco: es un resumen, y cada cosa que muestra tiene
  /// su propio módulo donde reintentar. Un bloque de error ahí taparía media
  /// pantalla por algo que el paciente no vino a ver.
  final Widget? alFallar;

  @override
  State<CargaDeDatos<T>> createState() => _CargaDeDatosState<T>();
}

class _CargaDeDatosState<T> extends State<CargaDeDatos<T>> {
  late Future<T> _futuro = widget.cargar();

  void _reintentar() {
    setState(() {
      _futuro = widget.cargar();
    });
  }

  bool _vacio(T datos) {
    if (widget.estaVacio case final f?) return f(datos);
    return datos is Iterable && datos.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _futuro,
      builder: (context, snapshot) {
        // El estado va antes que el error: al reintentar, FutureBuilder
        // arrastra el error viejo hasta que el futuro nuevo responde.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.alCargar ??
              const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          if (widget.alFallar case final w?) return w;
          return _Falla(
            mensaje: snapshot.error is FallaDatos
                ? (snapshot.error! as FallaDatos).mensaje
                : 'No pudimos cargar esta sección.',
            onReintentar: _reintentar,
          );
        }
        if (!snapshot.hasData) {
          return widget.alCargar ??
              const Center(child: CircularProgressIndicator());
        }

        final datos = snapshot.data as T;
        if (widget.vacio != null && _vacio(datos)) return widget.vacio!;

        return widget.constructor(context, datos);
      },
    );
  }
}

/// Lo que se muestra cuando la sección no tiene nada todavía.
///
/// Dice de quién depende que aparezca: el paciente no tiene forma de cargar
/// esto él mismo, y un vacío sin explicación se lee como que la app falló.
class SinDatos extends StatelessWidget {
  const SinDatos({super.key, required this.mensaje, this.icono});

  final String mensaje;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono case final i?) ...[
              Icon(i, size: 44, color: scheme.onSurfaceVariant),
              const SizedBox(height: 16),
            ],
            Text(
              mensaje,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Falla extends StatelessWidget {
  const _Falla({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onReintentar,
              child: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}
