import 'package:flutter/material.dart';

/// Suelta el foco —y con él el teclado— al tocar fuera de un campo de texto.
///
/// Va una sola vez en el `builder` de [MaterialApp] para que aplique a toda la
/// app, incluidos los diálogos y las hojas modales. Android no cierra el
/// teclado solo: mientras algo tenga el foco, la barra sigue arriba tapando
/// media pantalla aunque el paciente ya esté leyendo otra cosa.
class OcultarTeclado extends StatelessWidget {
  const OcultarTeclado({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // `translucent` deja pasar el toque a lo que haya debajo: el tap suelta
      // el foco y además hace lo que tenía que hacer.
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onTap: soltarFoco,
      child: child,
    );
  }

  /// Quita el foco del campo que lo tenga. Se llama también a mano antes de
  /// abrir una hoja o de cambiar de pestaña, donde el toque lo consume el
  /// widget de abajo y nunca llega hasta acá.
  static void soltarFoco() {
    final foco = FocusManager.instance.primaryFocus;
    if (foco != null && foco.hasFocus) foco.unfocus();
  }
}
