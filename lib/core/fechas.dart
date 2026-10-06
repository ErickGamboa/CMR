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
  return '$dia ${f.day} de ${_meses[f.month - 1]} · ${_hora(f)}';
}

/// Ej.: "10:30 a.m.".
String _hora(DateTime f) {
  final hora = f.hour % 12 == 0 ? 12 : f.hour % 12;
  final minuto = f.minute.toString().padLeft(2, '0');
  final periodo = f.hour < 12 ? 'a.m.' : 'p.m.';
  return '$hora:$minuto $periodo';
}

/// Cuánto hace, en palabras. Ej.: "hace 5 min", "ayer a las 3:40 p.m.",
/// "el 2 oct a las 9:15 a.m.".
String formatearHace(DateTime f, {DateTime? ahora}) {
  final ref = ahora ?? DateTime.now();
  final pasado = ref.difference(f);

  if (pasado.inMinutes < 1) return 'hace un momento';
  if (pasado.inMinutes < 60) return 'hace ${pasado.inMinutes} min';

  final hoy = DateTime(ref.year, ref.month, ref.day);
  final dia = DateTime(f.year, f.month, f.day);
  final dias = hoy.difference(dia).inDays;

  if (dias == 0) return 'hoy a las ${_hora(f)}';
  if (dias == 1) return 'ayer a las ${_hora(f)}';

  final fecha = '${f.day} ${_meses[f.month - 1].substring(0, 3)}';
  final anio = f.year == ref.year ? '' : ' ${f.year}';
  return 'el $fecha$anio a las ${_hora(f)}';
}
