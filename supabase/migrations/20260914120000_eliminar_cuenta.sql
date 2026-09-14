-- ---------------------------------------------------------------------------
-- El paciente borra su propia cuenta desde la app
-- ---------------------------------------------------------------------------
--
-- App Store y Google Play lo exigen: si la app deja crear una cuenta, tiene
-- que dejar borrarla desde adentro, sin mandar al usuario a escribir un correo.
--
-- El problema es que borrar un usuario de `auth.users` es Admin API, y la app
-- no puede llevar la llave `service_role` encima: cualquiera que abra el APK
-- la encuentra, y con ella se salta RLS y lee el expediente de todos.
--
-- La salida es esta función. Corre como su dueño (`security definer`), que sí
-- tiene permiso sobre `auth.users`, pero **no recibe ningún parámetro**: borra
-- `auth.uid()` y nada más. Aunque alguien la llame a mano desde fuera de la
-- app, lo único que puede borrar es su propia cuenta.
--
-- Al borrarse el usuario, todo lo suyo se va con él por las llaves foráneas
-- `on delete cascade`: ficha, citas, mediciones, laboratorios, recomendaciones,
-- prescripciones, plan, mapeo y favoritos. No queda una fila huérfana con
-- datos clínicos de alguien que pidió irse.

create or replace function eliminar_mi_cuenta()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  yo uuid := auth.uid();
begin
  if yo is null then
    raise exception 'No hay sesión.';
  end if;

  -- Un doctor no se borra solo desde acá: se quedaría la clínica sin quien
  -- administre y no hay pantalla para devolverle el permiso.
  if exists (select 1 from doctores d where d.user_id = yo) then
    raise exception 'Una cuenta de doctor no se borra desde la app.';
  end if;

  -- El cascade hace el resto.
  delete from auth.users where id = yo;
end;
$$;

comment on function eliminar_mi_cuenta() is
  'Borra la cuenta de quien la llama y todo lo suyo. Sin parámetros a '
  'propósito: solo puede borrar auth.uid().';

-- `anon` no la necesita: sin sesión no hay nada que borrar, y dejársela
-- disponible solo amplía la superficie.
revoke all on function eliminar_mi_cuenta() from public, anon;
grant execute on function eliminar_mi_cuenta() to authenticated;
