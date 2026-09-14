/// Formato de fechas en español sin depender de `intl`, que exigiría
/// inicializar locales solo para esto.
library;

const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'setiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

const _dias = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

/// Ej.: "8 de agosto, 2026".
String formatearFechaCorta(DateTime f) =>
    '${f.day} de ${_meses[f.month - 1]}, ${f.year}';

/// Ej.: "8 ago 2026". Para filtros y listas donde el espacio es poco.
String formatearFechaBreve(DateTime f) =>
    '${f.day} ${_meses[f.month - 1].substring(0, 3)} ${f.year}';

/// Abreviatura de tres letras con mayúscula inicial. Ej.: "Ago".
String mesCorto(DateTime f) {
  final m = _meses[f.month - 1];
  return m[0].toUpperCase() + m.substring(1, 3);
}

/// Ej.: "viernes 12 de setiembre, 2026". El día de la semana ayuda a ubicarse
/// cuando se navega el mapeo hacia atrás, día por día.
String formatearDiaConSemana(DateTime f) =>
    '${_dias[f.weekday - 1]} ${f.day} de ${_meses[f.month - 1]}, ${f.year}';

/// Ej.: "viernes 18 de setiembre · 10:30 a.m.".
String formatearFechaLarga(DateTime f) {
  final dia = _dias[f.weekday - 1];
  final hora = f.hour % 12 == 0 ? 12 : f.hour % 12;
  final minuto = f.minute.toString().padLeft(2, '0');
  final periodo = f.hour < 12 ? 'a.m.' : 'p.m.';

  return '$dia ${f.day} de ${_meses[f.month - 1]} · $hora:$minuto $periodo';
}
