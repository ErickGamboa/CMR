import 'package:flutter/material.dart';

/// Variantes disponibles del logo.
enum CmrLogoVariante {
  /// Monograma + tagline "Control Metabólico & Regenerativo".
  completo('assets/images/logo_cmr.png', 1385 / 991),

  /// Solo el monograma CMR con la hélice. Es el que va en el icono de app.
  marca('assets/images/logo_cmr_marca.png', 1385 / 828);

  const CmrLogoVariante(this.asset, this.proporcion);

  final String asset;

  /// Ancho / alto del arte recortado al contenido.
  final double proporcion;
}

/// Logo de CMR.
///
/// El arte es azul abisal sobre transparente, así que exige un fondo claro:
/// sobre superficie oscura el contraste cae a 1.15:1 y desaparece. Mientras no
/// exista una versión invertida, no usar sobre fondos oscuros.
class CmrLogo extends StatelessWidget {
  const CmrLogo({
    super.key,
    this.variante = CmrLogoVariante.completo,
    this.ancho,
    this.alto,
  }) : assert(
          ancho != null || alto != null,
          'Indicá ancho o alto para dimensionar el logo.',
        );

  final CmrLogoVariante variante;
  final double? ancho;
  final double? alto;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      variante.asset,
      width: ancho ?? alto! * variante.proporcion,
      height: alto ?? ancho! / variante.proporcion,
      fit: BoxFit.contain,
      // El logo es decorativo cuando va junto al nombre de la app; cuando va
      // solo, sí necesita nombre accesible.
      semanticLabel: 'CMR — Control Metabólico & Regenerativo',
    );
  }
}
