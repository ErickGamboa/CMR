-- Todo lo que el doctor le carga a UN paciente.
--
-- Mientras el sitio admin no exista, esto se corre a mano en el SQL Editor.
-- Buscá y reemplazá 'paciente@ejemplo.com' por el correo real, y corré solo
-- los bloques que ocupes: cada uno es independiente.
--
-- Nada de esto es obligatorio. Un paciente sin citas, sin laboratorios y sin
-- recetas abre la app y ve "Todavía no tienes…" en cada módulo, que es lo
-- correcto: mejor vacío que con datos de otro.
--
-- Para ver los correos y sus ids:  select id, email from auth.users;

-- ---------------------------------------------------------------------------
-- Citas
-- ---------------------------------------------------------------------------
--
-- La fecha va SIN zona horaria: es la hora del reloj de la clínica. Escribí
-- '2026-09-18 10:30' y el paciente ve 10:30 a.m.

insert into citas (paciente_id, fecha, tipo, profesional, especialidad, lugar)
select u.id, f.fecha, f.tipo, f.profesional, f.especialidad, f.lugar
  from auth.users u,
       (values
         ('2026-09-18 10:30'::timestamp, 'medica',
          'Dr. Nombre Apellido', 'Control metabólico', 'Clínica COSME - CMR'),
         ('2026-09-25 09:00'::timestamp, 'enfermeria',
          'Enfermería', 'Aplicación de péptidos', 'Clínica COSME - CMR')
       ) as f(fecha, tipo, profesional, especialidad, lugar)
 where u.email = 'paciente@ejemplo.com';

-- ---------------------------------------------------------------------------
-- Mediciones de composición corporal
-- ---------------------------------------------------------------------------
--
-- grasa_perdida y musculo_ganado son ACUMULADOS desde el inicio del plan, no
-- contra la medición anterior. La primera medición va con 0 y 0.

insert into mediciones (
  paciente_id, fecha, peso, porcentaje_grasa, grasa_visceral,
  grasa_perdida, musculo_ganado
)
select u.id, m.fecha, m.peso, m.grasa, m.visceral, m.perdida, m.ganado
  from auth.users u,
       (values
         ('2026-06-13'::date, 94.2, 34.1, 13.0, 0.0, 0.0),
         ('2026-08-08'::date, 88.9, 28.4,  9.0, 7.5, 2.2)
       ) as m(fecha, peso, grasa, visceral, perdida, ganado)
 where u.email = 'paciente@ejemplo.com'
    on conflict (paciente_id, fecha) do update
   set peso             = excluded.peso,
       porcentaje_grasa = excluded.porcentaje_grasa,
       grasa_visceral   = excluded.grasa_visceral,
       grasa_perdida    = excluded.grasa_perdida,
       musculo_ganado   = excluded.musculo_ganado;

-- ---------------------------------------------------------------------------
-- Laboratorios
-- ---------------------------------------------------------------------------
--
-- El examen primero, los analitos después colgando de él. `fuera_de_rango` lo
-- marca el doctor: la app no lo deduce, porque la referencia es texto libre.

with paciente as (
  select id from auth.users where email = 'paciente@ejemplo.com'
), examen as (
  insert into laboratorios (paciente_id, fecha, nombre)
  select id, '2026-08-08'::date, 'Perfil metabólico completo' from paciente
  returning id
)
insert into laboratorio_analisis (
  laboratorio_id, nombre, valor, unidad, referencia, fuera_de_rango, orden
)
select examen.id, a.nombre, a.valor, a.unidad, a.ref, a.fuera, a.orden
  from examen,
       (values
         ('Glucosa en ayunas',  '92',  'mg/dL', '70 – 99', false, 1),
         ('Emoglobina glicada', '5.8', '%',     '< 5.7',   true,  2),
         ('Colesterol total',   '178', 'mg/dL', '< 200',   false, 3)
       ) as a(nombre, valor, unidad, ref, fuera, orden);

-- ---------------------------------------------------------------------------
-- Recomendaciones
-- ---------------------------------------------------------------------------
--
-- El `icono` sale del catálogo cerrado de lib/core/iconos.dart: consejo, agua,
-- ejercicio, sueno, alimentacion, proteina, peso, corazon, ayuno, sol.

insert into recomendaciones (paciente_id, fecha, titulo, texto, icono)
select u.id, r.fecha, r.titulo, r.texto, r.icono
  from auth.users u,
       (values
         ('2026-08-16'::date, 'Sube la proteína en el desayuno',
          'Apunta a 30 g de proteína antes de las 10 a.m.', 'proteina'),
         ('2026-07-14'::date, 'Camina 20 minutos después de almorzar',
          'Ayuda a bajar el pico de glucosa de la tarde.', 'ejercicio')
       ) as r(fecha, titulo, texto, icono)
 where u.email = 'paciente@ejemplo.com';

-- ---------------------------------------------------------------------------
-- Suplementos, péptidos y medicamentos
-- ---------------------------------------------------------------------------
--
-- Los tres van en la misma tabla; el `tipo` decide en qué módulo aparecen:
--   suplemento  → Mi plan, pestaña Suplementos
--   peptido     → Péptidos y medicamentos, pestaña Péptidos
--   medicamento → Péptidos y medicamentos, pestaña Medicamentos
--
-- Para suspender algo NO lo borres: `update prescripciones set activo = false`.
-- Así queda el historial y la app deja de mostrarlo.

insert into prescripciones (
  paciente_id, tipo, nombre, dosis, frecuencia, indicacion, orden
)
select u.id, p.tipo, p.nombre, p.dosis, p.frecuencia, p.indicacion, p.orden
  from auth.users u,
       (values
         ('suplemento',  'Proteína de suero', '30 g', '1 vez al día',
          'Después del entrenamiento', 1),
         ('suplemento',  'Vitamina D3', '2000 UI', 'Diario',
          'Con el desayuno', 2),
         ('peptido',     'NOMBRE', 'DOSIS', 'FRECUENCIA',
          'Vía subcutánea', 1),
         ('medicamento', 'NOMBRE', '1 tableta', '2 veces al día',
          'Con el desayuno y la cena', 1)
       ) as p(tipo, nombre, dosis, frecuencia, indicacion, orden)
 where u.email = 'paciente@ejemplo.com';

-- ---------------------------------------------------------------------------
-- Revisar qué quedó cargado
-- ---------------------------------------------------------------------------

-- select 'citas' as tabla, count(*) from citas
--  where paciente_id = (select id from auth.users where email = 'paciente@ejemplo.com')
-- union all select 'mediciones', count(*) from mediciones
--  where paciente_id = (select id from auth.users where email = 'paciente@ejemplo.com')
-- union all select 'laboratorios', count(*) from laboratorios
--  where paciente_id = (select id from auth.users where email = 'paciente@ejemplo.com')
-- union all select 'recomendaciones', count(*) from recomendaciones
--  where paciente_id = (select id from auth.users where email = 'paciente@ejemplo.com')
-- union all select 'prescripciones', count(*) from prescripciones
--  where paciente_id = (select id from auth.users where email = 'paciente@ejemplo.com');
