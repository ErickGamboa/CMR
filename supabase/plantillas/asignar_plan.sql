-- Asignar un plan de alimentación a un paciente.
--
-- No es una migración: es la plantilla que se corre en el SQL Editor de
-- Supabase cada vez que el doctor le asigna o le cambia el plan a alguien.
--
-- Cómo usarla:
--   1. Cambiá el correo del paciente en `v_correo`.
--   2. Cambiá los números de las dos secciones de abajo.
--   3. Corré todo el bloque.
--
-- El plan que viene cargado de ejemplo es el de la tabla impresa:
-- carbohidratos (6), proteínas (11), lácteos (2), vegetales (4+), frutas (2)
-- y grasas (3).
--
-- Los grupos que no van en un tiempo de comida simplemente no se escriben:
-- eso es el guion de la tabla en papel. El `true` del final de una fila es el
-- "+", o sea que la cantidad es un mínimo y no un techo.

do $$
declare
  v_correo   text := 'paciente@ejemplo.com';   -- << cambiá esto
  v_paciente uuid;
  v_plan     uuid;
begin
  select id into v_paciente from auth.users where email = lower(v_correo);
  if v_paciente is null then
    raise exception 'No hay ningún usuario con el correo %', v_correo;
  end if;

  -- Un paciente tiene un solo plan activo: el anterior queda archivado, no se
  -- borra, para poder ver con qué plan venía.
  update planes_alimentacion
     set activo = false
   where paciente_id = v_paciente and activo;

  insert into planes_alimentacion (paciente_id, vigente_desde, notas)
  values (v_paciente, current_date, null)
  returning id into v_plan;

  -- ---------------------------------------------------------------------
  -- Total del día por grupo:  (grupo, cantidad, es_mínimo)
  -- ---------------------------------------------------------------------
  insert into plan_totales (plan_id, grupo, total, es_minimo) values
    (v_plan, 'carbohidratos',  6, false),
    (v_plan, 'proteinas',     11, false),
    (v_plan, 'lacteos',        2, false),
    (v_plan, 'vegetales',      4, true),
    (v_plan, 'frutas',         2, false),
    (v_plan, 'grasas',         3, false);

  -- ---------------------------------------------------------------------
  -- Reparto por tiempo de comida:  (grupo, tiempo, cantidad, es_mínimo)
  -- Tiempos: desayuno, merienda_manana, almuerzo, merienda_tarde, cena
  -- ---------------------------------------------------------------------
  insert into plan_distribucion (plan_id, grupo, tiempo, cantidad, es_minimo)
  values
    (v_plan, 'carbohidratos', 'desayuno',       1, false),
    (v_plan, 'proteinas',     'desayuno',       2, false),
    (v_plan, 'lacteos',       'desayuno',       1, false),
    (v_plan, 'vegetales',     'desayuno',       2, true),
    (v_plan, 'grasas',        'desayuno',       1, false),

    (v_plan, 'carbohidratos', 'almuerzo',       2, false),
    (v_plan, 'proteinas',     'almuerzo',       4, false),
    (v_plan, 'vegetales',     'almuerzo',       2, true),
    (v_plan, 'frutas',        'almuerzo',       1, false),
    (v_plan, 'grasas',        'almuerzo',       1, false),

    (v_plan, 'carbohidratos', 'merienda_tarde', 1, false),
    (v_plan, 'lacteos',       'merienda_tarde', 1, false),
    (v_plan, 'frutas',        'merienda_tarde', 1, false),

    (v_plan, 'carbohidratos', 'cena',           2, false),
    (v_plan, 'proteinas',     'cena',           5, false),
    (v_plan, 'vegetales',     'cena',           2, true),
    (v_plan, 'grasas',        'cena',           1, false);

  raise notice 'Plan % asignado a % (paciente %)', v_plan, v_correo, v_paciente;
end $$;
