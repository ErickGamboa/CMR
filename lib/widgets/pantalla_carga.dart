import 'dart:async';

import 'package:flutter/material.dart';

import 'cmr_logo.dart';

/// Pantalla de arranque con el logo completo.
///
/// Está calcada del splash nativo: mismo logo, mismo ancho y centrado en la
/// pantalla. Cuando el splash del sistema se va y aparece esta, no se ve
/// ningún cambio.
class PantallaCarga extends StatefulWidget {
  const PantallaCarga({super.key});

  /// 152 dp: el ancho al que el sistema dibuja el splash. Ver `_anchoSplash`
  /// en tool/build_brand_assets.dart.
  static const anchoLogo = 152.0;

  /// El indicador no aparece de una: si la carga es rápida, parpadearía. Solo
  /// se muestra cuando la espera ya se nota.
  static const esperaIndicador = Duration(milliseconds: 800);

  @override
  State<PantallaCarga> createState() => _PantallaCargaState();
}

class _PantallaCargaState extends State<PantallaCarga> {
  Timer? _temporizador;
  bool _mostrarIndicador = false;

  @override
  void initState() {
    super.initState();
    _temporizador = Timer(
      PantallaCarga.esperaIndicador,
      () => setState(() => _mostrarIndicador = true),
    );
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // El logo va en un Center propio y el indicador posicionado desde
          // abajo: si estuvieran en la misma Column, el indicador correría el
          // logo hacia arriba y el salto contra el splash volvería.
          const Center(child: CmrLogo(ancho: PantallaCarga.anchoLogo)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: Center(
              child: AnimatedOpacity(
                opacity: _mostrarIndicador ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: scheme.secondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
