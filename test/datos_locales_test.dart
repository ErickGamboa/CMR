import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cmr_app/core/datos/modelos.dart';
import 'package:cmr_app/core/datos/repositorio.dart';
import 'package:cmr_app/core/fechas.dart';
import 'package:cmr_app/core/local/almacen_local.dart';
import 'package:cmr_app/core/local/sincronizador.dart';
import 'package:cmr_app/features/mapeo/modelo_mapeo.dart';
import 'package:cmr_app/features/mapeo/repositorio_mapeo.dart';
import 'package:cmr_app/widgets/recarga.dart';

/// Hace de Supabase: responde lo que tenga, o falla como sin señal.
class _Nube {
  _Nube(this.tablas);

  final Map<String, Object?> tablas;
  bool caida = false;
  final pedidos = <String, int>{};

  Future<Object?> Function(SupabaseClient) bajar(String tabla) => (_) async {
    pedidos.update(tabla, (n) => n + 1, ifAbsent: () => 1);
    // Un respiro, para que dos pedidos simultáneos se puedan cruzar.
    await Future<void>.delayed(Duration.zero);
    if (caida) throw const SocketException('sin red');
    return tablas[tabla];
  };
}

/// Un cliente que no llega a ningún lado: los conjuntos de prueba no lo usan
/// para bajar, y lo que sí lo usa (la subida del mapeo) tiene que fallar.
SupabaseClient _clienteSinRed() => SupabaseClient(
  'http://127.0.0.1:9',
  'clave-de-prueba',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

void main() {
  // El control de recarga avisa por el planificador de cuadros.
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Nube nube;
  late AlmacenEnMemoria almacen;
  late ControlRecarga recarga;
  late SupabaseClient cliente;
  String? paciente = 'paciente-1';

  Sincronizador crear({List<Conjunto>? conjuntos}) {
    final s = Sincronizador(
      almacen: almacen,
      cliente: cliente,
      recarga: recarga,
      paciente: () => paciente,
      conjuntos:
          conjuntos ??
          [
            Conjunto(Claves.citas, nube.bajar('citas')),
            Conjunto(Claves.prescripciones, nube.bajar('prescripciones')),
            Conjunto(Claves.modulos, nube.bajar('modulos')),
            Conjunto(Claves.mapeo, nube.bajar('mapeo'), modulo: 'mapeo'),
            Conjunto(Claves.videos, nube.bajar('videos'), publico: true),
          ],
    );
    addTearDown(s.dispose);
    return s;
  }

  setUp(() {
    paciente = 'paciente-1';
    almacen = AlmacenEnMemoria();
    recarga = ControlRecarga();
    cliente = _clienteSinRed();
    nube = _Nube({
      'citas': [
        {
          'fecha': '2026-10-20T15:00:00Z',
          'tipo': 'medica',
          'profesional': 'Dra. Prueba',
          'especialidad': 'Control',
          'lugar': 'Clínica',
        },
      ],
      'prescripciones': [
        {'tipo': 'peptido', 'nombre': 'BPC-157', 'dosis': '250 mcg'},
        {'tipo': 'suplemento', 'nombre': 'Magnesio', 'dosis': '400 mg'},
      ],
      'modulos': <String>[],
      'mapeo': <Object>[],
      'videos': <Object>[],
    });
  });

  tearDown(() {
    recarga.dispose();
    cliente.dispose();
  });

  group('leer', () {
    test(
      'la primera vez baja; después sale del teléfono, haya red o no',
      () async {
        final datos = crear();

        expect(await datos.filas(Claves.citas), hasLength(1));
        expect(nube.pedidos['citas'], 1);

        nube.caida = true;
        expect(await datos.filas(Claves.citas), hasLength(1));
        expect(nube.pedidos['citas'], 1, reason: 'no vuelve a pedirlo');
      },
    );

    test('sin nada guardado y sin red, falla', () async {
      nube.caida = true;
      final datos = crear();

      await expectLater(
        datos.filas(Claves.citas),
        throwsA(isA<SocketException>()),
      );
    });

    test('lo de un paciente no lo lee otro en el mismo teléfono', () async {
      final datos = crear();
      await datos.leer(Claves.citas);

      paciente = 'paciente-2';
      nube.tablas['citas'] = <Object>[];

      expect(await datos.filas(Claves.citas), isEmpty);
      expect(nube.pedidos['citas'], 2, reason: 'lo baja para el segundo');
    });

    test('sin sesión no lee nada del paciente', () async {
      paciente = null;
      final datos = crear();

      await expectLater(datos.leer(Claves.citas), throwsA(isA<FallaDatos>()));
    });

    test('el catálogo público no depende de la sesión', () async {
      paciente = null;
      final datos = crear();

      expect(await datos.filas(Claves.videos), isEmpty);
    });
  });

  group('sincronizar', () {
    test('reemplaza lo guardado y avisa a las pantallas', () async {
      final datos = crear();
      await datos.leer(Claves.citas);
      final generacion = recarga.generacion;

      nube.tablas['citas'] = <Object>[];
      await datos.sincronizar();

      expect(await datos.filas(Claves.citas), isEmpty);
      expect(recarga.generacion, generacion + 1);
      expect(datos.ultimaVez, isNotNull);
      expect(datos.sinConexion, isFalse);
    });

    test('sin red conserva lo guardado y lo dice', () async {
      final datos = crear();
      await datos.sincronizar();
      final ultima = datos.ultimaVez;

      nube.caida = true;
      await datos.sincronizar();

      expect(await datos.filas(Claves.citas), hasLength(1));
      expect(datos.sinConexion, isTrue);
      expect(datos.ultimaVez, ultima, reason: 'sigue siendo la de antes');
    });

    test('la flechita gira mientras baja', () async {
      final datos = crear();

      final enCurso = datos.sincronizar();
      expect(recarga.cargando, isTrue);
      expect(datos.ocupado, isTrue);

      await enCurso;
      expect(recarga.cargando, isFalse);
      expect(datos.ocupado, isFalse);
    });

    test('dos pedidos a la vez son una sola descarga', () async {
      final datos = crear();

      await Future.wait([datos.sincronizar(), datos.sincronizar()]);

      expect(nube.pedidos['citas'], 1);
    });

    test('una tabla que el servidor rechaza no es "sin conexión"', () async {
      final datos = crear(
        conjuntos: [
          Conjunto(Claves.citas, nube.bajar('citas')),
          Conjunto(
            Claves.videos,
            (_) async => throw const PostgrestException(
              message: 'no existe',
              code: '42P01',
            ),
            publico: true,
          ),
        ],
      );

      await datos.sincronizar();

      expect(datos.sinConexion, isFalse);
      expect(await datos.filas(Claves.citas), hasLength(1));
    });

    test('el mapeo solo se baja si el paciente lo tiene prendido', () async {
      final datos = crear();

      await datos.sincronizar();
      expect(nube.pedidos['mapeo'], isNull);

      nube.tablas['modulos'] = ['mapeo'];
      await datos.sincronizar();
      expect(nube.pedidos['mapeo'], 1);
    });

    test('lo que llega tarde de una sesión cerrada no se guarda', () async {
      final datos = crear();

      final enCurso = datos.sincronizar();
      await datos.vaciar();
      await enCurso;

      expect(await almacen.leer('paciente-1/${Claves.citas}'), isNull);
    });
  });

  test('vaciar borra todo lo guardado', () async {
    final datos = crear();
    await datos.sincronizar();

    await datos.vaciar();

    expect(await almacen.leer('paciente-1/${Claves.citas}'), isNull);
    expect(await almacen.leer('publico/${Claves.videos}'), isNull);
    expect(datos.ultimaVez, isNull);
  });

  group('repositorio del paciente', () {
    test('arma los modelos desde la copia local', () async {
      final repo = RepositorioPaciente(crear());

      final citas = await repo.citas();
      expect(citas.single.profesional, 'Dra. Prueba');
    });

    test('cada tipo de receta sale de la misma descarga', () async {
      final repo = RepositorioPaciente(crear());

      final peptidos = await repo.prescripciones(TipoPrescripcion.peptido);
      final suplementos = await repo.prescripciones(
        TipoPrescripcion.suplemento,
      );

      expect(peptidos.single.nombre, 'BPC-157');
      expect(suplementos.single.nombre, 'Magnesio');
      expect(nube.pedidos['prescripciones'], 1);
    });

    test('sin nada guardado y sin red, el mensaje se entiende', () async {
      nube.caida = true;
      final repo = RepositorioPaciente(crear());

      await expectLater(
        repo.citas(),
        throwsA(
          isA<FallaDatos>().having(
            (f) => f.mensaje,
            'mensaje',
            contains('conexión'),
          ),
        ),
      );
    });
  });

  group('mapeo sin conexión', () {
    final hoy = DateTime(2026, 10, 6);

    RegistroMapeo registro(String ayunas) =>
        RegistroMapeo(fecha: hoy, valores: {MomentoMapeo.ayunas: ayunas});

    test(
      'guardar sin red queda en el teléfono y se ve en el historial',
      () async {
        nube.tablas['mapeo'] = [
          {
            'tipo': 'presion',
            'fecha': '2026-10-05',
            'ayunas': '118/76',
            'libre': null,
            'antes_de_dormir': null,
          },
        ];
        final repo = RepositorioMapeo(crear());

        final subido = await repo.guardar(
          TipoMapeo.presion,
          registro('120/80'),
        );

        expect(subido, isFalse);
        final historial = await repo.historial(TipoMapeo.presion);
        expect(historial.map((r) => r.valorDe(MomentoMapeo.ayunas)), [
          '120/80',
          '118/76',
        ]);
      },
    );

    test('lo pendiente manda sobre lo bajado, también para borrar', () async {
      nube.tablas['mapeo'] = [
        {
          'tipo': 'presion',
          'fecha': '2026-10-06',
          'ayunas': '130/85',
          'libre': null,
          'antes_de_dormir': null,
        },
      ];
      final datos = crear();
      final repo = RepositorioMapeo(datos);

      await repo.guardar(TipoMapeo.presion, registro('120/80'));
      expect(
        (await repo.historial(
          TipoMapeo.presion,
        )).single.valorDe(MomentoMapeo.ayunas),
        '120/80',
      );

      await repo.guardar(
        TipoMapeo.presion,
        RegistroMapeo(fecha: hoy, valores: {}),
      );
      expect(await repo.historial(TipoMapeo.presion), isEmpty);

      // Y sigue en la cola, una sola vez: lo último que se anotó ese día.
      final cola = await ColaMapeo(datos).pendientes();
      expect(cola, hasLength(1));
    });

    test('lo anotado de un tipo no aparece en el otro', () async {
      final repo = RepositorioMapeo(crear());

      await repo.guardar(TipoMapeo.glisemia, registro('95'));

      expect(await repo.historial(TipoMapeo.presion), isEmpty);
      expect(await repo.historial(TipoMapeo.glisemia), hasLength(1));
    });
  });

  group('formatearHace', () {
    final ahora = DateTime(2026, 10, 6, 15, 40);

    test('lo reciente va en minutos', () {
      expect(
        formatearHace(
          ahora.subtract(const Duration(seconds: 20)),
          ahora: ahora,
        ),
        'hace un momento',
      );
      expect(
        formatearHace(ahora.subtract(const Duration(minutes: 5)), ahora: ahora),
        'hace 5 min',
      );
    });

    test('lo de hoy, ayer y antes va con la hora', () {
      expect(
        formatearHace(DateTime(2026, 10, 6, 9, 5), ahora: ahora),
        'hoy a las 9:05 a.m.',
      );
      expect(
        formatearHace(DateTime(2026, 10, 5, 21, 0), ahora: ahora),
        'ayer a las 9:00 p.m.',
      );
      expect(
        formatearHace(DateTime(2026, 10, 2, 12, 30), ahora: ahora),
        'el 2 oct a las 12:30 p.m.',
      );
      expect(
        formatearHace(DateTime(2025, 12, 31, 8, 0), ahora: ahora),
        'el 31 dic 2025 a las 8:00 a.m.',
      );
    });
  });
}
