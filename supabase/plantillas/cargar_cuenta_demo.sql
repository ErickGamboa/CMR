-- ---------------------------------------------------------------------------
-- Llenar la cuenta de demostración
-- ---------------------------------------------------------------------------
--
-- Deja todos los módulos de la app con algo adentro, para que quien revise la
-- app en la App Store y en Google Play no se encuentre nueve pantallas que
-- dicen "Todavía no tienes…". Un revisor que entra y no ve nada concluye que
-- la app no funciona, y rechaza.
--
-- Se corre en el SQL Editor de Supabase. La cuenta tiene que existir antes:
-- se crea desde la app con "Crear una cuenta", o desde el sitio en
-- Pacientes → Nuevo paciente.
--
-- **Se puede correr las veces que haga falta.** Cada bloque borra primero lo
-- que ya tenía esta cuenta y vuelve a insertar, así que no se duplica nada y
-- siempre queda igual. Por eso mismo no lo corrás contra un paciente de
-- verdad: le borraría el expediente.
--
-- Las fechas son relativas a `current_date`, para que la próxima cita siga
-- siendo futura dentro de tres meses sin tener que tocar el archivo.
--
-- Si la cuenta de demostración cambia de correo, buscá y reemplazá
-- appletest@gmail.com en todo el archivo. Va escrito literal en cada bloque
-- a propósito: el editor SQL de Supabase no es psql y no entiende variables.

-- ---------------------------------------------------------------------------
-- 0. La ficha, y que la cuenta esté aprobada
-- ---------------------------------------------------------------------------
--
-- Sin `estado = 'activo'` la app no muestra nada: se queda en la pantalla de
-- "tu cuenta está en revisión", que es justo lo que el revisor no puede ver.

update pacientes p
   set nombre           = 'Ana',
       apellidos        = 'Solís Vargas',
       cedula           = '1-0888-0999',
       telefono         = '8888-0000',
       fecha_nacimiento = '1979-04-12',
       estado           = 'activo',
       aprobado_en      = now()
  from auth.users u
 where u.id = p.user_id and u.email = 'appletest@gmail.com';

-- ---------------------------------------------------------------------------
-- 1. Citas
-- ---------------------------------------------------------------------------
--
-- Una pasada y una futura: el Home muestra "próxima cita" y el módulo de
-- citas muestra las dos listas.

delete from citas
 where paciente_id = (select id from auth.users where email = 'appletest@gmail.com');

insert into citas (paciente_id, fecha, tipo, profesional, especialidad, lugar)
select u.id, current_date + f.dias + f.hora, f.tipo, f.profesional,
       f.especialidad, 'Clínica COSME - CMR'
  from auth.users u,
       (values
         (  9, '10:30'::time, 'medica',     'Dr. Roy Jiménez',
            'Control metabólico'),
         ( 23, '09:00'::time, 'enfermeria', 'Enfermería',
            'Aplicación de péptidos'),
         (-19, '11:00'::time, 'medica',     'Dr. Roy Jiménez',
            'Primera consulta')
       ) as f(dias, hora, tipo, profesional, especialidad)
 where u.email = 'appletest@gmail.com';

-- ---------------------------------------------------------------------------
-- 2. Mediciones
-- ---------------------------------------------------------------------------
--
-- Tres, con progreso: el Home dibuja las barras de grasa perdida y músculo
-- ganado comparando la última contra la anterior. Con una sola no hay qué
-- comparar y la tarjeta se ve a medias.
--
-- Ojo: `grasa_perdida` y `musculo_ganado` son ACUMULADOS desde el inicio del
-- plan, no contra la medición anterior. La primera va en 0 y 0.

delete from mediciones
 where paciente_id = (select id from auth.users where email = 'appletest@gmail.com');

insert into mediciones (
  paciente_id, fecha, peso, porcentaje_grasa, grasa_visceral,
  grasa_perdida, musculo_ganado
)
select u.id, current_date - m.dias, m.peso, m.grasa, m.visceral,
       m.perdida, m.ganado
  from auth.users u,
       (values
         (104, 91.4, 36.2, 12.0, 0.0, 0.0),
         ( 47, 86.1, 32.5, 10.0, 5.8, 1.4),
         (  5, 82.3, 29.8,  8.0, 9.6, 2.7)
       ) as m(dias, peso, grasa, visceral, perdida, ganado)
 where u.email = 'appletest@gmail.com';

-- ---------------------------------------------------------------------------
-- 3. Laboratorios
-- ---------------------------------------------------------------------------
--
-- Dos exámenes para que se vea la evolución. Los nombres y las unidades salen
-- del mismo catálogo que usa el sitio (`catalogo_analitos`), y sin rango de
-- referencia, que es como trabaja la clínica: la app ya no dibuja la línea
-- "Ref." cuando viene vacía.

delete from laboratorios
 where paciente_id = (select id from auth.users where email = 'appletest@gmail.com');

with paciente as (
  select id from auth.users where email = 'appletest@gmail.com'
), examen as (
  insert into laboratorios (paciente_id, fecha, nombre)
  select id, current_date - 47, 'Perfil metabólico' from paciente
  returning id
)
insert into laboratorio_analisis (
  laboratorio_id, nombre, valor, unidad, referencia, fuera_de_rango, orden
)
select examen.id, a.nombre, a.valor, a.unidad, '', a.fuera, a.orden
  from examen,
       (values
         ('Glucosa en ayunas',    '104', 'mg/dl', true,   3),
         ('Hemoglobina glicada',  '5.9', '%',     true,   4),
         ('Triglicéridos',        '188', 'mg/dl', true,  11),
         ('Colesterol total',     '206', 'mg/dl', true,  12),
         ('HDL',                  '41',  'mg/dl', false, 14),
         ('TSH',                  '2.4', 'uUI/ml', false, 17),
         ('Vitamina D',           '22',  'ng/ml', true,  18)
       ) as a(nombre, valor, unidad, fuera, orden);

with paciente as (
  select id from auth.users where email = 'appletest@gmail.com'
), examen as (
  insert into laboratorios (paciente_id, fecha, nombre)
  select id, current_date - 5, 'Perfil metabólico de control' from paciente
  returning id
)
insert into laboratorio_analisis (
  laboratorio_id, nombre, valor, unidad, referencia, fuera_de_rango, orden
)
select examen.id, a.nombre, a.valor, a.unidad, '', a.fuera, a.orden
  from examen,
       (values
         ('Glucosa en ayunas',    '94',  'mg/dl', false,  3),
         ('Hemoglobina glicada',  '5.4', '%',     false,  4),
         ('Triglicéridos',        '132', 'mg/dl', false, 11),
         ('Colesterol total',     '181', 'mg/dl', false, 12),
         ('HDL',                  '52',  'mg/dl', false, 14),
         ('Vitamina D',           '38',  'ng/ml', false, 18),
         ('Ferritina',            '96',  'ng/ml', false, 20)
       ) as a(nombre, valor, unidad, fuera, orden);

-- ---------------------------------------------------------------------------
-- 4. Recomendaciones
-- ---------------------------------------------------------------------------
--
-- Los textos y los íconos son los del catálogo del doctor
-- (`catalogo_indicaciones`, tipo 'recomendacion'), para que la demostración
-- muestre lo mismo que el doctor indica de verdad.

delete from recomendaciones
 where paciente_id = (select id from auth.users where email = 'appletest@gmail.com');

insert into recomendaciones (paciente_id, fecha, titulo, texto, icono)
select u.id, current_date - r.dias, r.titulo, r.texto, r.icono
  from auth.users u,
       (values
         (47, 'Hidratación', 'Tomar 2.5 litros de agua al día', 'agua'),
         (47, 'Medir los carbohidratos',
              'Utilizar tazas medidoras para servir carbohidratos',
              'alimentacion'),
         (47, 'Pesar la proteína', 'Pesar la proteína cocinada', 'proteina'),
         (5,  'Horas de sueño', 'Dormir en promedio 7 horas', 'sueno'),
         (5,  'Sin embutidos', 'No consumir embutidos', 'evitar'),
         (5,  'Hidratación en el ejercicio',
              'Durante el ejercicio hidratarse constantemente, aparte de su requerimiento diario',
              'ejercicio')
       ) as r(dias, titulo, texto, icono)
 where u.email = 'appletest@gmail.com';

-- ---------------------------------------------------------------------------
-- 5. Suplementos, péptidos y medicamentos
-- ---------------------------------------------------------------------------
--
-- El `tipo` decide en qué módulo aparece cada uno:
--   suplemento  → Mi plan, pestaña Suplementos
--   peptido     → Péptidos y medicamentos, pestaña Péptidos
--   medicamento → Péptidos y medicamentos, pestaña Medicamentos
--
-- Los cuatro campos son los que dibuja la tarjeta de la app: nombre, el chip
-- de dosis, el de frecuencia y la indicación en prosa. Están escritos como
-- los arma el catálogo del sitio.

delete from prescripciones
 where paciente_id = (select id from auth.users where email = 'appletest@gmail.com');

insert into prescripciones (
  paciente_id, tipo, nombre, dosis, frecuencia, indicacion, orden
)
select u.id, p.tipo, p.nombre, p.dosis, p.frecuencia,
       nullif(p.indicacion, ''), p.orden
  from auth.users u,
       (values
         ('suplemento', 'Creatina monohidratada', '5 g',
          'En cualquier momento del día', '', 1),
         ('suplemento', 'Omega 3', '2 g', 'Al día',
          'Siempre con comidas con grasa saludable', 2),
         ('suplemento', 'Vitamina D / Vitamina K2', '5000 UI', 'Al día',
          'Siempre con el desayuno', 3),
         ('suplemento', 'Glicinato de magnesio', '400-800 mg',
          'Antes de dormir', 'Glicinato o bisglicinato', 4),
         ('suplemento', 'Probióticos Synbiotic+', '1 cápsula(s)',
          '2 veces al día', 'Siempre con comidas', 5),

         ('peptido', 'Semaglutide', '0.5 mg', 'A la semana', '', 1),
         ('peptido', 'CJC/Ipa — antes de dormir', '10 unidades',
          'Antes de dormir', '', 2),
         ('peptido', 'BPC-157', '10 U', 'Por día',
          'En cualquier momento, por 12 semanas', 3),

         ('medicamento', 'Metformina', '850 mg', '2 veces al día', '', 1),
         ('medicamento', 'Omeprazol', '1 tableta', 'Por 14 días',
          'En ayunas', 2)
       ) as p(tipo, nombre, dosis, frecuencia, indicacion, orden)
 where u.email = 'appletest@gmail.com';

-- ---------------------------------------------------------------------------
-- 6. Plan de alimentación
-- ---------------------------------------------------------------------------
--
-- El total del día NO se escribe a mano: es la suma de lo que se reparte
-- entre los tiempos de comida, igual que lo calcula el sitio. Acá va escrito
-- porque es un script, pero los números cuadran con el reparto de abajo.

delete from planes_alimentacion
 where paciente_id = (select id from auth.users where email = 'appletest@gmail.com');

with paciente as (
  select id from auth.users where email = 'appletest@gmail.com'
), plan as (
  insert into planes_alimentacion (paciente_id, vigente_desde, activo, notas)
  select id, current_date - 47, true,
         'Pesar la proteína ya cocinada. Las verduras de hoja verde son libres.'
    from paciente
  returning id
), reparto as (
  insert into plan_distribucion (plan_id, grupo, tiempo, cantidad, es_minimo)
  select plan.id, d.grupo::grupo_intercambio, d.tiempo::tiempo_comida,
         d.cantidad, d.minimo
    from plan,
         (values
           ('carbohidratos', 'desayuno',        1.0, false),
           ('carbohidratos', 'almuerzo',        1.0, false),
           ('carbohidratos', 'cena',            1.0, false),
           ('proteinas',     'desayuno',        2.0, false),
           ('proteinas',     'almuerzo',        3.0, false),
           ('proteinas',     'cena',            3.0, false),
           ('lacteos',       'desayuno',        1.0, false),
           ('lacteos',       'merienda_tarde',  1.0, false),
           ('vegetales',     'almuerzo',        2.0, true),
           ('vegetales',     'cena',            2.0, true),
           ('frutas',        'merienda_manana', 1.0, false),
           ('frutas',        'merienda_tarde',  1.0, false),
           ('grasas',        'almuerzo',        1.0, false),
           ('grasas',        'cena',            1.0, false)
         ) as d(grupo, tiempo, cantidad, minimo)
  returning plan_id
)
insert into plan_totales (plan_id, grupo, total, es_minimo)
select plan.id, t.grupo::grupo_intercambio, t.total, t.minimo
  from plan,
       (values
         ('carbohidratos', 3.0, false),
         ('proteinas',     8.0, false),
         ('lacteos',       2.0, false),
         ('vegetales',     4.0, true),
         ('frutas',        2.0, false),
         ('grasas',        2.0, false)
       ) as t(grupo, total, minimo);

-- ---------------------------------------------------------------------------
-- 7. Mapeo
-- ---------------------------------------------------------------------------
--
-- Es un módulo que el doctor prende por paciente. Sin la fila en
-- `pacientes_modulos` ni siquiera aparece en el menú de la app, así que el
-- revisor no lo vería.
--
-- Los registros los escribe el paciente, no el doctor. Van cargados igual
-- para que el módulo se abra con algo y se entienda de qué va.

insert into pacientes_modulos (paciente_id, modulo, habilitado)
select u.id, 'mapeo', true from auth.users u where u.email = 'appletest@gmail.com'
on conflict (paciente_id, modulo) do update set habilitado = true;

delete from mapeo_registros
 where paciente_id = (select id from auth.users where email = 'appletest@gmail.com');

insert into mapeo_registros (
  paciente_id, tipo, fecha, ayunas, libre, antes_de_dormir
)
select u.id, r.tipo, current_date - r.dias, r.ayunas, r.libre, r.noche
  from auth.users u,
       (values
         ('presion',  0, '118/76', null,    '122/80'),
         ('presion',  1, '121/79', '126/82', '119/77'),
         ('presion',  3, '124/81', null,    '120/78'),
         ('glisemia', 0, '92',     '134',   '101'),
         ('glisemia', 1, '89',     null,    '97'),
         ('glisemia', 3, '95',     '141',   '104')
       ) as r(tipo, dias, ayunas, libre, noche)
 where u.email = 'appletest@gmail.com';

-- ---------------------------------------------------------------------------
-- Comprobar qué quedó
-- ---------------------------------------------------------------------------

select 'estado de la cuenta' as que, estado as cuantos
  from pacientes
 where user_id = (select id from auth.users where email = 'appletest@gmail.com')
union all
select 'citas', count(*)::text from citas
 where paciente_id = (select id from auth.users where email = 'appletest@gmail.com')
union all
select 'mediciones', count(*)::text from mediciones
 where paciente_id = (select id from auth.users where email = 'appletest@gmail.com')
union all
select 'laboratorios', count(*)::text from laboratorios
 where paciente_id = (select id from auth.users where email = 'appletest@gmail.com')
union all
select 'recomendaciones', count(*)::text from recomendaciones
 where paciente_id = (select id from auth.users where email = 'appletest@gmail.com')
union all
select 'prescripciones', count(*)::text from prescripciones
 where paciente_id = (select id from auth.users where email = 'appletest@gmail.com')
union all
select 'plan de alimentación', count(*)::text from planes_alimentacion
 where paciente_id = (select id from auth.users where email = 'appletest@gmail.com')
union all
select 'registros de mapeo', count(*)::text from mapeo_registros
 where paciente_id = (select id from auth.users where email = 'appletest@gmail.com');
