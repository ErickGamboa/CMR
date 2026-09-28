-- ---------------------------------------------------------------------------
-- Cómo se parte una indicación en lo que ve el paciente
-- ---------------------------------------------------------------------------
--
-- `plantilla` es la frase completa, tal como la escribió el doctor en su
-- lista. Pero la tarjeta de la app no muestra una frase: muestra un nombre, un
-- chip de dosis resaltado, un chip de frecuencia y, debajo, la indicación en
-- prosa (lib/widgets/tarjeta_prescripcion.dart).
--
--     Creatina Monohidratada            ← nombre
--     [ 5 g ]  ( En cualquier momento ) ← dosis · frecuencia
--     Siempre con comidas               ← indicación
--
-- Ese corte es semántico: no sale de partir el texto por una coma. Así que se
-- declara acá, una vez por plantilla, con los mismos {huecos} que la frase
-- completa. El doctor llena un número y cae en los cuatro pedazos.
--
-- Las recomendaciones no usan esto: van a un solo campo de texto.

alter table catalogo_indicaciones
  add column if not exists plantilla_nombre     text,
  add column if not exists plantilla_dosis      text,
  add column if not exists plantilla_frecuencia text,
  add column if not exists plantilla_indicacion text;

comment on column catalogo_indicaciones.plantilla_nombre is
  'Solo cuando el nombre sale de un hueco (cuál de tres fármacos). Si es null manda `nombre`.';
comment on column catalogo_indicaciones.plantilla_dosis is
  'El chip resaltado de la app. Null en una plantilla agregada después: ahí la frase entera cae en la indicación.';

-- ---------------------------------------------------------------------------
-- Dos medicamentos que estaban como un hueco suelto
-- ---------------------------------------------------------------------------
--
-- La lista del doctor trae "Metformina ___" y "Levotiroxina ___": un solo
-- espacio para todo. Con un hueco único no hay chip de dosis que llenar, así
-- que se abre en dos, que es como igual los iba a escribir.

insert into catalogo_indicaciones
  (id, tipo, nombre, plantilla, campos, titulo, icono, libre, orden)
values
  ('med-metformina', 'medicamento', 'Metformina',
   'Metformina {dosis}, {frecuencia}',
   '[{"clave":"dosis","etiqueta":"Dosis","tipo":"texto"},
     {"clave":"frecuencia","etiqueta":"Frecuencia","tipo":"texto"}]',
   null, null, false, 2),

  ('med-levotiroxina', 'medicamento', 'Levotiroxina',
   'Levotiroxina {dosis}, {frecuencia}',
   '[{"clave":"dosis","etiqueta":"Dosis","tipo":"texto"},
     {"clave":"frecuencia","etiqueta":"Frecuencia","tipo":"texto"}]',
   null, null, false, 3)

on conflict (id) do update
  set plantilla = excluded.plantilla,
      campos    = excluded.campos;

-- ---------------------------------------------------------------------------
-- El corte de cada plantilla
-- ---------------------------------------------------------------------------

update catalogo_indicaciones as c
   set plantilla_nombre     = nullif(v.nombre, ''),
       plantilla_dosis      = v.dosis,
       plantilla_frecuencia = v.frecuencia,
       plantilla_indicacion = v.indicacion
  from (values

-- id                   nombre       dosis                                frecuencia                      indicación
  ('sup-creatina',      '', '{dosis} g',                          'En cualquier momento del día', ''),
  ('sup-omega3',        '', '{dosis} g',                          'Al día',                       'Siempre con comidas con grasa saludable'),
  ('sup-vitd-k2',       '', '{dosis} UI',                         'Al día',                       'Siempre con el desayuno'),
  ('sup-beta-alanina',  '', '{dosis} g',                          'Al día',                       'En cualquier momento del día'),
  ('sup-remolacha',     '', '2 tabletas',                         'Al día',                       ''),
  ('sup-mct',           '', '{dosis} g',                          'Al día',                       'En ayuno o preentrenamiento'),
  ('sup-mg-treonato',   '', '{dosis} mg',                         'Antes de dormir',              ''),
  ('sup-mg-glicinato',  '', '{dosis} mg',                         'Antes de dormir',              'Glicinato o bisglicinato'),
  ('sup-mg-citrato',    '', '{dosis} mg',                         'Antes de dormir',              ''),
  ('sup-probioticos',   '', '{capsulas} cápsula(s)',              '2 veces al día',               'Siempre con comidas'),
  ('sup-melatonina',    '', '{dosis} mg',                         'Antes de dormir',              ''),
  ('sup-gaba',          '', '500 mg',                             'Antes de dormir',              ''),
  ('sup-ashwagandha',   '', '{dosis} g',                          'Antes de dormir',              ''),
  ('sup-cafeina',       '', '{dosis} mg',                         'Antes del ejercicio',          ''),
  ('sup-curcuma',       '', '2 tabletas o cápsulas',              'En la mañana',                 ''),
  ('sup-triptofano',    '', '1 g',                                'En cualquier momento del día', ''),
  ('sup-alfalipoico',   '', '1 g',                                'En cualquier momento del día', ''),
  ('sup-psyllium',      '', '{dosis} g',                          '2 veces al día',               ''),
  ('sup-zinc',          '', '{dosis} mg de zinc elemental',       'Con comida',                   ''),
  ('sup-nac',           '', '600 mg',                             '{veces} veces al día',         'En cualquier momento del día'),
  ('sup-proteina',      '', '{scoops} scoop',                     'Al día',                       'De cualquier sabor'),

  ('pep-semaglutide',   '', '{dosis} mg',                         'A la semana',                  ''),
  ('pep-tirzepatide',   '', '{dosis} mg',                         'A la semana',                  ''),
  ('pep-retatrutide',   '', '{dosis} mg',                         'A la semana',                  ''),
  ('pep-cjc-noche',     '', '10 unidades',                        'Antes de dormir',              ''),
  ('pep-cjc-dos-veces', '', '10 unidades',                        '2 veces al día',               'En ayunas y antes de dormir'),
  ('pep-mots',          '', '{unidades} unidades ({dosis} mg)',   '{veces} veces por semana',     'Antes de entrenar o en la mañana, por 4 semanas'),
  ('pep-aod',           '', '{unidades} U o {dosis} mg',          'Diaria',                       'En ayunas o antes del ejercicio, por {semanas} semanas'),
  ('pep-bpc157',        '', '10 U',                               'Por día',                      'En cualquier momento, por 12 semanas'),
  ('pep-epithalon',     '', '{unidades} unidades ({dosis} mg)',   'Antes de dormir',              'Por {dias} días'),
  ('pep-ghk-cu',        '', '{unidades} unidades ({dosis} mg)',   'Por día',                      'Por {semanas} semanas'),
  ('pep-glow',          '', '{unidades} unidades ({dosis} mg)',   'Por día',                      'Por 8 semanas'),
  ('pep-pt141',         '', '{disparos} disparo(s) por fosa nasal', 'Antes del acto sexual',
                            'Al menos 2 horas antes. No más de 1 uso en 24 horas ni más de 3 usos por semana'),
  ('pep-tb500',         '', '{unidades} unidades ({dosis} mg)',   'Al día',                       'Por {semanas} semanas'),
  ('pep-tesamorelin',   '', '{unidades} unidades',                'Por día',                      'Por 10 días, descanso de 10 días, y continúa por otros 10 días'),
  ('pep-thymosin',      '', '{unidades} unidades',                'Por día',                      'Por {semanas} semanas'),
  ('pep-semax',         '', '{unidades} unidades',                'Por día',                      'Por 4 semanas'),
  ('pep-selank',        '', '{unidades} unidades',                'Por día',                      'Por 4 semanas'),
  ('pep-semax-selank',  '', '{disparos} disparo(s) por fosa nasal', 'Por día',                    'Por {semanas} semanas'),
  ('pep-dsip',          '', '{disparos} disparo(s) por fosa nasal', 'Por día',                    'Por {semanas} semanas'),
  ('pep-nad',           '', '{disparos} disparo(s) por fosa nasal', 'Por día',                    'Por {semanas} semanas'),

  ('med-femoston',      '', '{dosis} mg, 1 tableta',              'Por día',                      'A la misma hora'),
  ('med-metformina',    '', '{dosis}',                            '{frecuencia}',                 ''),
  ('med-levotiroxina',  '', '{dosis}',                            '{frecuencia}',                 ''),
  ('med-ibp',           '{farmaco}', '1 tableta',                 'Por {dias} días',              'En ayunas')

  ) as v(id, nombre, dosis, frecuencia, indicacion)
 where c.id = v.id;
