"use server";

import { revalidatePath } from "next/cache";

import { clienteServidor } from "@/lib/supabase/servidor";

// Un archivo "use server" solo puede exportar funciones async. Los tipos sí
// (se borran al compilar); las constantes van en el componente de cliente.
export type Resultado = { error: string | null; guardado: boolean };

export async function guardarRecomendacion(
  _anterior: Resultado,
  datos: FormData,
): Promise<Resultado> {
  const paciente = String(datos.get("paciente") ?? "");
  const titulo = String(datos.get("titulo") ?? "").trim();
  const texto = String(datos.get("texto") ?? "").trim();
  const icono = String(datos.get("icono") ?? "consejo");
  const fecha = String(datos.get("fecha") ?? "").trim();

  if (!paciente) return { error: "Falta el paciente.", guardado: false };
  if (!titulo) return { error: "Escribí el título.", guardado: false };
  if (!texto) return { error: "Escribí la recomendación.", guardado: false };

  const supabase = await clienteServidor();
  const { data, error } = await supabase
    .from("recomendaciones")
    .insert({
      paciente_id: paciente,
      titulo,
      texto,
      icono,
      ...(fecha ? { fecha } : {}),
    })
    .select("id");

  if (error || !data || data.length === 0) {
    return {
      error: "No pudimos guardarla. Intenta de nuevo.",
      guardado: false,
    };
  }

  revalidatePath(`/pacientes/${paciente}/atender/recomendaciones`);
  return { error: null, guardado: true };
}

export async function borrarRecomendacion(paciente: string, id: string) {
  const supabase = await clienteServidor();
  const { error } = await supabase
    .from("recomendaciones")
    .delete()
    .eq("id", id);

  if (error) return { error: "No pudimos borrarla." };

  revalidatePath(`/pacientes/${paciente}/atender/recomendaciones`);
  return { error: null };
}
