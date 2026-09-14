/// Las dos cosas que el paciente mapea en casa.
enum TipoMapeo {
  presion(
    valor: 'presion',
    etiqueta: 'Presión arterial',
    ejemplo: 'ej. 120/80',
  ),
  glisemia(valor: 'glisemia', etiqueta: 'Glisemia', ejemplo: 'ej. 95 mg/dL');

  const TipoMapeo({
    required this.valor,
    required this.etiqueta,
    required this.ejemplo,
  });

  /// Como se guarda en la columna `tipo`.
  final String valor;

  final String etiqueta;

  /// Pista de qué escribir. Es solo un ejemplo: el campo acepta texto libre.
  final String ejemplo;
}

/// Las tres casillas de un día, en el orden de la hoja del doctor.
enum MomentoMapeo {
  ayunas(columna: 'ayunas', etiqueta: 'En ayunas'),

  // En el papel esta casilla no tiene nombre: es un "*" y ya. Es la medición
  // suelta, la que el paciente se tomó a cualquier hora.
  libre(
    columna: 'libre',
    etiqueta: '*',
    ayuda: 'Medición suelta, a cualquier hora',
  ),

  antesDeDormir(columna: 'antes_de_dormir', etiqueta: 'Antes de dormir');

  const MomentoMapeo({
    required this.columna,
    required this.etiqueta,
    this.ayuda,
  });

  final String columna;
  final String etiqueta;
  final String? ayuda;
}

/// Lo anotado un día. Hay a lo sumo uno por día y por tipo: el paciente
/// corrige el del día, no acumula varios.
class RegistroMapeo {
  RegistroMapeo({
    required DateTime fecha,
    required Map<MomentoMapeo, String> valores,
  }) : fecha = soloDia(fecha),
       valores = {
         for (final e in valores.entries)
           if (e.value.trim().isNotEmpty) e.key: e.value.trim(),
       };

  factory RegistroMapeo.desdeFila(Map<String, dynamic> fila) => RegistroMapeo(
    fecha: DateTime.parse(fila['fecha'] as String),
    valores: {
      for (final m in MomentoMapeo.values)
        m: (fila[m.columna] as String?) ?? '',
    },
  );

  /// Solo la fecha: la hora no significa nada acá y arruinaría las
  /// comparaciones entre días.
  final DateTime fecha;

  /// Solo los momentos con algo escrito.
  final Map<MomentoMapeo, String> valores;

  String valorDe(MomentoMapeo momento) => valores[momento] ?? '';

  /// Sin nada anotado no es un registro: guardarlo así es borrarlo.
  bool get vacio => valores.isEmpty;

  /// Fecha en el formato que espera Postgres para un `date`. Es también la
  /// llave con que el historial se guarda en memoria.
  String get fechaIso => claveDe(fecha);

  static String claveDe(DateTime f) =>
      '${f.year.toString().padLeft(4, '0')}-'
      '${f.month.toString().padLeft(2, '0')}-'
      '${f.day.toString().padLeft(2, '0')}';

  static DateTime soloDia(DateTime f) => DateTime(f.year, f.month, f.day);

  static bool mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
