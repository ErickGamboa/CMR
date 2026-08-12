import 'package:flutter/material.dart';

/// Paleta oficial CMR. No usar colores fuera de esta clase.
abstract final class AppColors {
  /// Azul abisal — color primario de marca.
  static const azulAbisal = Color(0xFF090972);

  /// Turquesa biocelular — color secundario.
  static const turquesaBiocelular = Color(0xFF62A1A6);

  /// Azul vital — color de acento / realces.
  static const azulVital = Color(0xFF86DBFB);

  // Neutros derivados, usados solo para superficies y texto.
  static const superficie = Color(0xFFFFFFFF);
  static const superficieAlterna = Color(0xFFF4F7FA);
  static const superficieOscura = Color(0xFF0B0B2B);
  static const superficieOscuraAlterna = Color(0xFF13133F);
  static const textoPrincipal = Color(0xFF10102E);
  static const textoSecundario = Color(0xFF5B5F73);
  static const error = Color(0xFFB3261E);
}
