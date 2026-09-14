-- Prender o apagar un módulo opcional para un paciente.
--
-- Mientras el sitio admin no exista, esto se corre a mano en el SQL Editor.
-- El único módulo opcional hoy es 'mapeo'.

-- Prenderlo:
insert into pacientes_modulos (paciente_id, modulo, habilitado)
values ('00000000-0000-0000-0000-000000000000', 'mapeo', true)
on conflict (paciente_id, modulo) do update set habilitado = excluded.habilitado;

-- Apagarlo (deja la fila, por si se vuelve a prender):
-- update pacientes_modulos set habilitado = false
--  where paciente_id = '00000000-0000-0000-0000-000000000000'
--    and modulo = 'mapeo';

-- Ver quién lo tiene prendido:
-- select u.email, m.modulo, m.habilitado
--   from pacientes_modulos m
--   join auth.users u on u.id = m.paciente_id
--  order by u.email;
