import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../modulos.dart';

/// Fila horizontal de accesos rápidos.
///
/// Arranca centrada, con fichas asomando a ambos lados, para que se vea de
/// entrada que hay más módulos en las dos direcciones. Dos flechas muy tenues
/// refuerzan la pista y se desvanecen al llegar a cada extremo.
class FilaModulosSecundarios extends StatefulWidget {
  const FilaModulosSecundarios({
    super.key,
    required this.modulos,
    required this.onSeleccion,
  });

  /// Los módulos que este paciente ve. No siempre son todos: los opcionales
  /// dependen de lo que el doctor le haya habilitado.
  final List<ModuloSecundario> modulos;

  final void Function(ModuloSecundario) onSeleccion;

  /// Alto fijo de la fila. Inicio le reserva el lugar mientras resuelve qué
  /// módulos van, para que la pantalla no salte al aparecer.
  static const double alto = 108;

  @override
  State<FilaModulosSecundarios> createState() => _FilaModulosSecundariosState();
}

class _FilaModulosSecundariosState extends State<FilaModulosSecundarios> {
  static const _separacion = 12.0;
  static const _paddingH = 16.0;
  static const _paddingFicha = 8.0;
  static const _anchoMinimo = 92.0;

  ScrollController? _ctrl;
  late double _anchoFicha;
  bool _hayIzquierda = false;
  bool _hayDerecha = false;

  /// Ancho que necesita la etiqueta más larga para entrar en una sola línea.
  ///
  /// Se mide en vez de fijarse a mano: así ninguna etiqueta se corta, ni hoy
  /// ni cuando se agregue un módulo con nombre más largo, y respeta el tamaño
  /// de letra que el usuario haya configurado en el sistema.
  double _medirAnchoFicha() {
    final estilo = Theme.of(context).textTheme.labelSmall;
    final escala = MediaQuery.textScalerOf(context);
    var ancho = 0.0;

    for (final modulo in ModuloSecundario.values) {
      final medidor = TextPainter(
        text: TextSpan(text: modulo.etiqueta, style: estilo),
        textDirection: TextDirection.ltr,
        textScaler: escala,
        maxLines: 1,
      )..layout();
      ancho = math.max(ancho, medidor.width);
    }

    return math.max(_anchoMinimo, ancho + _paddingFicha * 2);
  }

  double get _anchoContenido {
    final n = widget.modulos.length;
    return n * _anchoFicha + (n - 1) * _separacion + _paddingH * 2;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _anchoFicha = _medirAnchoFicha();
    if (_ctrl != null) return;

    // El desplazamiento inicial se calcula acá y no en un post-frame porque
    // el ancho de las fichas ya se conoce: así la fila aparece centrada en el
    // primer cuadro, sin salto visible.
    final desborde = math.max(
      0.0,
      _anchoContenido - MediaQuery.sizeOf(context).width,
    );

    _ctrl = ScrollController(initialScrollOffset: desborde / 2)
      ..addListener(_actualizarFlechas);
    _hayIzquierda = desborde > 0;
    _hayDerecha = desborde > 0;
  }

  void _actualizarFlechas() {
    final pos = _ctrl!.position;
    final izquierda = pos.pixels > 1;
    final derecha = pos.pixels < pos.maxScrollExtent - 1;

    if (izquierda != _hayIzquierda || derecha != _hayDerecha) {
      setState(() {
        _hayIzquierda = izquierda;
        _hayDerecha = derecha;
      });
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: FilaModulosSecundarios.alto,
      child: Stack(
        children: [
          Positioned.fill(
            child: ListView.separated(
              controller: _ctrl,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _paddingH),
              itemCount: widget.modulos.length,
              separatorBuilder: (_, _) => const SizedBox(width: _separacion),
              itemBuilder: (context, i) {
                final modulo = widget.modulos[i];
                return _Acceso(
                  modulo: modulo,
                  ancho: _anchoFicha,
                  onTap: () => widget.onSeleccion(modulo),
                );
              },
            ),
          ),
          _Flecha(visible: _hayIzquierda, izquierda: true),
          _Flecha(visible: _hayDerecha, izquierda: false),
        ],
      ),
    );
  }
}

/// Pista de que hay más contenido hacia ese lado.
///
/// Deliberadamente tenue: un degradado corto del color del fondo que difumina
/// la ficha del borde, y un chevron al 45% de opacidad. No intercepta toques,
/// para no robarle el borde de la ficha que tiene debajo.
class _Flecha extends StatelessWidget {
  const _Flecha({required this.visible, required this.izquierda});

  final bool visible;
  final bool izquierda;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borde = izquierda ? Alignment.centerLeft : Alignment.centerRight;
    final centro = izquierda ? Alignment.centerRight : Alignment.centerLeft;

    return Positioned(
      top: 0,
      bottom: 0,
      left: izquierda ? 0 : null,
      right: izquierda ? null : 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: Container(
            width: 34,
            alignment: borde,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: borde,
                end: centro,
                colors: [scheme.surface, scheme.surface.withValues(alpha: 0)],
              ),
            ),
            child: Icon(
              izquierda ? Icons.chevron_left : Icons.chevron_right,
              size: 18,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}

class _Acceso extends StatelessWidget {
  const _Acceso({
    required this.modulo,
    required this.ancho,
    required this.onTap,
  });

  final ModuloSecundario modulo;
  final double ancho;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      width: ancho,
      child: Material(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(modulo.icono, size: 22, color: scheme.primary),
                ),
                const SizedBox(height: 8),
                // Una sola línea: la ficha ya viene dimensionada para que la
                // etiqueta más larga entre entera.
                Text(
                  modulo.etiqueta,
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
