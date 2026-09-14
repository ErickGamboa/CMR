"use server";

import { revalidatePath } from "next/cache";

import { doctorActual } from "@/lib/doctor";
import { clienteServidor } from "@/lib/supabase/servidor";

/**
 * Prende o apaga el módulo Mapeo para este paciente.
 *
 * Sin fila en `pacientes_modulos` el módulo está apagado, así que prenderlo es
 * insertar y apagarlo es dejar la fila en `false`. Se deja la fila y no se
 * borra para que quede el rastro de que alguna vez estuvo prendido.
 */
export async function cambiarMapeo(paciente: string, habilitado: boolean) {
  const doctor = await doctorActual();
  if (!doctor) return { error: "Tu sesión no es de un doctor." };

  const supabase = await clienteServidor();
  const { data, error } = await supabase
    .from("pacientes_modulos")
    .upsert(
      { paciente_id: paciente, modulo: "mapeo", habilitado },
      { onConflict: "paciente_id,modulo" },
    )
    .select("modulo");

  if (error || !data || data.length === 0) {
    return { error: "No pudimos cambiar el módulo." };
  }

  revalidatePath(`/pacientes/${paciente}/atender/mapeo`);
  return { error: null };
}
