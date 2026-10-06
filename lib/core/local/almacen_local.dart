import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Lo último que se bajó de un conjunto de datos, y cuándo.
class Foto {
  const Foto(this.datos, this.bajada);

  /// Las filas tal como vinieron de Supabase, ya decodificadas. Puede ser
  /// `null` cuando eso es lo que respondió el servidor (ej. no hay plan
  /// activo), que no es lo mismo que no tener foto.
  final Object? datos;

  final DateTime bajada;
}

/// Dónde vive en el teléfono la copia de los datos.
///
/// Guarda "fotos": por cada consulta, las filas tal como las devolvió
/// Supabase, en JSON. No replica el esquema de Postgres tabla por tabla a
/// propósito: la app nunca edita estos datos, solo los vuelve a leer, así que
/// no hay nada que ganar con un esquema local y sí mucho que mantener cada vez
/// que cambie el de la nube.
abstract interface class AlmacenLocal {
  Future<Foto?> leer(String clave);

  Future<void> guardar(String clave, Object? datos);

  Future<void> borrar(String clave);

  /// Borra todo. Se usa al cerrar sesión: son datos de salud y no se quedan
  /// en un teléfono sin dueño.
  Future<void> vaciar();
}

/// La copia en SQLite, que es lo que sobrevive a cerrar la app.
class AlmacenSqlite implements AlmacenLocal {
  AlmacenSqlite._(this._db);

  final Database _db;

  static Future<AlmacenSqlite> abrir() async {
    final ruta = p.join(await getDatabasesPath(), 'cmr_local.db');
    final db = await openDatabase(
      ruta,
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE fotos ('
        'clave TEXT PRIMARY KEY, '
        'datos TEXT NOT NULL, '
        'bajada INTEGER NOT NULL)',
      ),
    );
    return AlmacenSqlite._(db);
  }

  @override
  Future<Foto?> leer(String clave) async {
    final filas = await _db.query(
      'fotos',
      columns: ['datos', 'bajada'],
      where: 'clave = ?',
      whereArgs: [clave],
    );
    if (filas.isEmpty) return null;

    final fila = filas.first;
    return Foto(
      jsonDecode(fila['datos']! as String),
      DateTime.fromMillisecondsSinceEpoch(fila['bajada']! as int),
    );
  }

  @override
  Future<void> guardar(String clave, Object? datos) => _db.insert('fotos', {
    'clave': clave,
    'datos': jsonEncode(datos),
    'bajada': DateTime.now().millisecondsSinceEpoch,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<void> borrar(String clave) =>
      _db.delete('fotos', where: 'clave = ?', whereArgs: [clave]);

  @override
  Future<void> vaciar() => _db.delete('fotos');
}

/// La copia en memoria: dura lo que dura la app abierta.
///
/// Es el plan B si SQLite no abre (disco lleno, por ejemplo). La app sigue
/// funcionando igual con internet; lo único que se pierde es ver los datos
/// sin conexión después de cerrarla. También la usan los tests.
class AlmacenEnMemoria implements AlmacenLocal {
  final _fotos = <String, (String, DateTime)>{};

  @override
  Future<Foto?> leer(String clave) async {
    final guardada = _fotos[clave];
    if (guardada == null) return null;

    // Pasa por JSON igual que SQLite, para que quien lea reciba los mismos
    // tipos en los dos almacenes.
    return Foto(jsonDecode(guardada.$1), guardada.$2);
  }

  @override
  Future<void> guardar(String clave, Object? datos) async {
    _fotos[clave] = (jsonEncode(datos), DateTime.now());
  }

  @override
  Future<void> borrar(String clave) async => _fotos.remove(clave);

  @override
  Future<void> vaciar() async => _fotos.clear();
}
