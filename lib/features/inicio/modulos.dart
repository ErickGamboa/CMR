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
  mapeo('Mapeo', Icons.monitor_heart_outlined, clave: 'mapeo'),
  leerEtiqueta('Leer etiqueta', Icons.document_scanner_outlined),
  recomendaciones('Recomendaciones', Icons.lightbulb_outline),
  videos('Videos', Icons.play_circle_outline);

  const ModuloSecundario(this.etiqueta, this.icono, {this.clave});

  final String etiqueta;
  final IconData icono;

  /// Nombre del módulo en `pacientes_modulos`. Sin clave, el módulo lo ve
  /// cualquier paciente; con clave, solo el que el doctor haya habilitado.
  final String? clave;

  bool get esOpcional => clave != null;

  /// Los que ve cualquier paciente, sin preguntarle nada al servidor. Es lo
  /// que se muestra mientras carga la lista y si la consulta falla.
  static List<ModuloSecundario> get abiertos =>
      values.where((m) => !m.esOpcional).toList();

  /// Los abiertos más los opcionales que el paciente tenga prendidos, en el
  /// orden del enum.
  static List<ModuloSecundario> visibles(Set<String> habilitados) => values
      .where((m) => !m.esOpcional || habilitados.contains(m.clave))
      .toList();
}
