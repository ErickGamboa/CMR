import { clienteServidor, usuarioActual } from "@/lib/supabase/servidor";

export type Doctor = { userId: string; nombre: string; correo: string };

/**
 * El doctor de la sesión, o `null` si quien entró no lo es.
 *
 * Tener cuenta no es ser doctor: los pacientes usan el mismo Supabase Auth que
 * el sitio, así que cualquiera de ellos podría llegar hasta acá con una sesión
 * válida. Lo que separa a uno de otro es una fila en `doctores`.
 *
 * No hace falta comparar nada a mano: la política de RLS de esa tabla solo
 * deja leerla a quien ya es doctor, así que a un paciente la consulta le sale
 * vacía. Si esta función devuelve algo, la base ya lo autorizó.
 */
export async function doctorActual(): Promise<Doctor | null> {
  const usuario = await usuarioActual();
  if (!usuario) return null;

  const supabase = await clienteServidor();
  const { data } = await supabase
    .from("doctores")
    .select("user_id, nombre")
    .eq("user_id", usuario.id)
    .maybeSingle();

  if (!data) return null;

  return {
    userId: data.user_id as string,
    nombre: data.nombre as string,
    correo: usuario.email ?? "",
  };
}
