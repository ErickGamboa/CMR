-- ---------------------------------------------------------------------------
-- La consulta como una cosa con principio y final
-- ---------------------------------------------------------------------------
--
-- El indicador de pasos palomeaba lo que el paciente tuviera cargado alguna
-- vez. A la segunda visita eso deja los siete pasos en verde desde que se
-- abre, y el doctor pierde lo único que el indicador sirve para decirle: qué
-- ya tocó **hoy**.
--
-- Así que la visita se guarda. El botón "Siguiente" de cada paso lo marca en
-- la consulta abierta, y "Terminar consulta" la cierra. La siguiente empieza
-- limpia.
--
-- Lo marca el botón y no las acciones que guardan: el visto es el doctor
-- diciendo "con este paso ya terminé", que no es lo mismo que "acá hay datos".
-- Puede guardar tres veces mientras corrige y seguir sin dar el paso por
-- cerrado, y puede saltar al paso 5 tocando el número del indicador sin que
-- los cuatro anteriores se palomeen solos.

create table if not exists consultas (
  id           uuid primary key default gen_random_uuid(),
  paciente_id  uuid not null references auth.users(id) on delete cascade,
  doctor_id    uuid not null references auth.users(id) on delete cascade,

  abierta_en   timestamptz not null default now(),
  cerrada_en   timestamptz,

  -- Las claves de `admin/src/lib/pasos.ts`. Texto suelto a propósito: el día
  -- que se agregue o se renombre un paso, el historial viejo no tiene por qué
  -- dejar de cargar.
  pasos        text[] not null default '{}'
);

-- Una abierta por paciente, garantizado por la base y no por la aplicación:
-- dos pestañas del sitio abriendo la misma consulta es un accidente normal.
create unique index if not exists consultas_abierta_idx
  on consultas (paciente_id) where cerrada_en is null;

create index if not exists consultas_paciente_idx
  on consultas (paciente_id, abierta_en desc);

comment on table consultas is
  'Una visita. Sirve para saber qué pasos se tocaron en esta y no en las anteriores.';

alter table consultas enable row level security;

drop policy if exists consultas_doctor on consultas;
create policy consultas_doctor on consultas
  for all to authenticated using (es_doctor()) with check (es_doctor());

-- ---------------------------------------------------------------------------
-- Marcar un paso
-- ---------------------------------------------------------------------------
--
-- Va como función y no como tres consultas desde el sitio porque leer la
-- consulta abierta, decidir si hay que crear una y agregarle el paso tiene que
-- pasar de una sola vez: si no, dos guardados seguidos abren dos consultas o
-- uno le pisa el arreglo al otro.

create or replace function marcar_paso(p_paciente uuid, p_paso text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  if not es_doctor() then
    raise exception 'Solo el doctor puede marcar pasos de una consulta';
  end if;

  -- Una consulta que nadie cerró no puede arrastrar los palomeos a la visita
  -- de la otra semana. Pasadas 12 horas se da por terminada sola.
  update consultas
     set cerrada_en = abierta_en + interval '12 hours'
   where paciente_id = p_paciente
     and cerrada_en is null
     and abierta_en < now() - interval '12 hours';

  select id into v_id
    from consultas
   where paciente_id = p_paciente and cerrada_en is null;

  if v_id is null then
    insert into consultas (paciente_id, doctor_id)
    values (p_paciente, auth.uid())
    returning id into v_id;
  end if;

  update consultas
     set pasos = (select array_agg(distinct x) from unnest(pasos || p_paso) as x)
   where id = v_id;
end;
$$;

revoke all on function marcar_paso(uuid, text) from public;
grant execute on function marcar_paso(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Cerrarla
-- ---------------------------------------------------------------------------
--
-- Sin consulta abierta no hace nada, que es lo correcto: el doctor puede
-- apretar "Terminar consulta" después de entrar a mirar sin tocar nada.

create or replace function cerrar_consulta(p_paciente uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not es_doctor() then
    raise exception 'Solo el doctor puede cerrar una consulta';
  end if;

  update consultas
     set cerrada_en = now()
   where paciente_id = p_paciente and cerrada_en is null;
end;
$$;

revoke all on function cerrar_consulta(uuid) from public;
grant execute on function cerrar_consulta(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- El doctor de la clínica
-- ---------------------------------------------------------------------------

update doctores set nombre = 'Dr. Roy Jiménez'
 where nombre = 'Dr. Nombre Apellido';
