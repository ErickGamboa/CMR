import 'package:flutter/material.dart';

/// Módulos primarios: las secciones de la barra inferior.
enum ModuloPrimario {
  inicio(
    etiqueta: 'Inicio',
    titulo: 'Inicio',
    icono: Icons.home_outlined,
    iconoActivo: Icons.home,
  ),
  libro(
    etiqueta: 'Libro',
    titulo: 'Libro',
    icono: Icons.menu_book_outlined,
    iconoActivo: Icons.menu_book,
  ),
  plan(
    etiqueta: 'Mi plan',
    titulo: 'Mi plan',
    icono: Icons.assignment_outlined,
    iconoActivo: Icons.assignment,
  ),
  // La etiqueta de la barra va corta a propósito: "Péptidos y medicamentos"
  // no entra en un quinto de pantalla y se cortaría. Igual "Mis citas", que
  // en la barra va como "Citas".
  peptidos(
    etiqueta: 'Péptidos',
    titulo: 'Péptidos y medicamentos',
    icono: Icons.medication_outlined,
    iconoActivo: Icons.medication,
  ),
  citas(
    etiqueta: 'Citas',
    titulo: 'Mis citas',
    icono: Icons.event_outlined,
    iconoActivo: Icons.event,
  );

  const ModuloPrimario({
    required this.etiqueta,
    required this.titulo,
    required this.icono,
    required this.iconoActivo,
  });

  /// Texto de la barra inferior.
  final String etiqueta;

  /// Título completo dentro de la pantalla.
  final String titulo;

  final IconData icono;
  final IconData iconoActivo;
}

/// Módulos secundarios: la fila de accesos rápidos del Home.
enum ModuloSecundario {
  laboratorios('Laboratorios', Icons.science_outlined),
  resultados('Resultados', Icons.insights_outlined),
  leerEtiqueta('Leer etiqueta', Icons.document_scanner_outlined),
  recomendaciones('Recomendaciones', Icons.lightbulb_outline),
  videos('Videos', Icons.play_circle_outline);

  const ModuloSecundario(this.etiqueta, this.icono);

  final String etiqueta;
  final IconData icono;
}
