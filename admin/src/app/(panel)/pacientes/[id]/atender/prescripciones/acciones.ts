"use server";

import { revalidatePath } from "next/cache";

import { clienteServidor } from "@/lib/supabase/servidor";

export type Resultado = { error: string | null; guardado: boolean };

export async function guardarPrescripcion(
  _anterior: Resultado,
  datos: FormData,
): Promise<Resultado> {
  const paciente = String(datos.get("paciente") ?? "");
  const tipo = String(datos.get("tipo") ?? "suplemento");
  const nombre = String(datos.get("nombre") ?? "").trim();
  const dosis = String(datos.get("dosis") ?? "").trim();
  const frecuencia = String(datos.get("frecuencia") ?? "").trim();
  const indicacion = String(datos.get("indicacion") ?? "").trim();

  if (!paciente) return { error: "Falta el paciente.", guardado: false };
  if (!nombre) return { error: "Escribí el nombre.", guardado: false };
  if (!dosis) return { error: "Escribí la dosis.", guardado: false };
  if (!frecuencia) return { error: "Escribí la frecuencia.", guardado: false };

  const supabase = await clienteServidor();
  const { data, error } = await supabase
    .from("prescripciones")
    .insert({
      paciente_id: paciente,
      tipo,
      nombre,
      dosis,
      frecuencia,
      indicacion: indicacion || null,
    })
    .select("id");

  if (error || !data || data.length === 0) {
    return {
      error: "No pudimos guardarla. Intenta de nuevo.",
      guardado: false,
    };
  }

  revalidatePath(`/pacientes/${paciente}/atender/prescripciones`);
  return { error: null, guardado: true };
}

/**
 * Suspender no es borrar: el historial se conserva y la app deja de mostrarlo.
 * Borrar de verdad se deja para lo que se cargó por error.
 */
export async function cambiarActivo(
  paciente: string,
  id: string,
  activo: boolean,
) {
  const supabase = await clienteServidor();
  const { error } = await supabase
    .from("prescripciones")
    .update({ activo })
    .eq("id", id);

  if (error) return { error: "No pudimos cambiarla." };

  revalidatePath(`/pacientes/${paciente}/atender/prescripciones`);
  return { error: null };
}

export async function borrarPrescripcion(paciente: string, id: string) {
  const supabase = await clienteServidor();
  const { error } = await supabase.from("prescripciones").delete().eq("id", id);

  if (error) return { error: "No pudimos borrarla." };

  revalidatePath(`/pacientes/${paciente}/atender/prescripciones`);
  return { error: null };
}
