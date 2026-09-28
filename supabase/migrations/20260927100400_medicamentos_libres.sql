-- ---------------------------------------------------------------------------
-- Metformina y Levotiroxina vuelven a un solo espacio
-- ---------------------------------------------------------------------------
--
-- La migración anterior las abrió en dos campos, dosis y frecuencia, para que
-- llenaran los dos chips de la tarjeta de la app. No es lo que la clínica
-- quiere: en estas dos el doctor escoge el medicamento y escribe la
-- indicación entera de corrido, como está en su lista.
--
--     2. Metformina ___    (espacio libre para indicación)
--     3. Levotiroxina ___  (espacio libre para indicación)
--
-- Así que el hueco vuelve a ser uno solo y cae en la indicación, el campo en
-- prosa. Estas dos quedan sin chip de dosis ni de frecuencia, y la tarjeta ya
-- no los dibuja cuando vienen vacíos (lib/widgets/tarjeta_prescripcion.dart).

insert into catalogo_indicaciones
  (id, tipo, nombre, plantilla, campos, titulo, icono, libre, orden)
values
  ('med-metformina', 'medicamento', 'Metformina',
   'Metformina {indicacion}',
   '[{"clave":"indicacion","etiqueta":"Indicación","tipo":"texto"}]',
   null, null, false, 2),

  ('med-levotiroxina', 'medicamento', 'Levotiroxina',
   'Levotiroxina {indicacion}',
   '[{"clave":"indicacion","etiqueta":"Indicación","tipo":"texto"}]',
   null, null, false, 3)

on conflict (id) do update
  set plantilla = excluded.plantilla,
      campos    = excluded.campos;

update catalogo_indicaciones
   set plantilla_nombre     = null,
       plantilla_dosis      = '',
       plantilla_frecuencia = '',
       plantilla_indicacion = '{indicacion}'
 where id in ('med-metformina', 'med-levotiroxina');
