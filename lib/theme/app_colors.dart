import 'package:flutter/material.dart';

/// Paleta oficial CMR. No usar colores fuera de esta clase.
abstract final class AppColors {
  /// Azul abisal — color primario de marca.
  static const azulAbisal = Color(0xFF090972);

  /// Turquesa biocelular — color secundario.
  static const turquesaBiocelular = Color(0xFF62A1A6);

  /// Azul vital — color de acento / realces.
  static const azulVital = Color(0xFF86DBFB);

  // Colores de dato, no de marca: identifican a los seis grupos de
  // intercambio en las píldoras del libro. Van fuera de los tres colores de
  // marca a propósito —con tres no se distinguen seis grupos— y cada par está
  // escogido para pasar 4.5:1 de contraste del texto sobre su fondo.
  static const pildoraCarbohidratos =
      (fondo: Color(0xFFE3E3F5), texto: Color(0xFF090972));
  static const pildoraFrutas =
      (fondo: Color(0xFFFFE7E9), texto: Color(0xFF8C1D2B));
  static const pildoraProteinas =
      (fondo: Color(0xFFFFEEDD), texto: Color(0xFF8A4B12));
  static const pildoraVegetales =
      (fondo: Color(0xFFE2F0E4), texto: Color(0xFF1F5B2A));
  static const pildoraLacteos =
      (fondo: Color(0xFFDFF3FE), texto: Color(0xFF14536B));
  static const pildoraGrasas =
      (fondo: Color(0xFFFFF6D9), texto: Color(0xFF6B4E00));

  // Neutros derivados, usados solo para superficies y texto.
  static const superficie = Color(0xFFFFFFFF);
  static const superficieAlterna = Color(0xFFF4F7FA);
  static const superficieOscura = Color(0xFF0B0B2B);
  static const superficieOscuraAlterna = Color(0xFF13133F);
  static const textoPrincipal = Color(0xFF10102E);
  static const textoSecundario = Color(0xFF5B5F73);
  static const error = Color(0xFFB3261E);
}
