import { notFound } from "next/navigation";

import { EstadoPacienteBadge } from "@/components/estado-paciente";
import { Volver } from "@/components/volver";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { COLUMNAS_PACIENTE, type Paciente } from "@/lib/pacientes";
import { PASOS, type ClavePaso } from "@/lib/pasos";
import { clienteServidor } from "@/lib/supabase/servidor";

import { PasosNav } from "./pasos-nav";

/**
 * El marco de la consulta: quién es el paciente y en qué paso vamos.
 *
 * Va en un layout y no en cada paso para que la cabecera y el indicador no se
 * vuelvan a dibujar al cambiar de paso. Así el avance se siente como moverse
 * dentro de una misma pantalla, no como cargar otra.
 */
export default async function LayoutAtender({
  children,
  params,
}: LayoutProps<"/pacientes/[id]/atender">) {
  const { id } = await params;
  const supabase = await clienteServidor();

  const { data } = await supabase
    .from("pacientes")
    .select(COLUMNAS_PACIENTE)
    .eq("user_id", id)
    .maybeSingle();

  const paciente = data as unknown as Paciente | null;
  if (!paciente) notFound();

  // Los conteos salen en paralelo: son siete consultas chiquitas y esperarlas
  // en fila multiplicaría por siete lo que tarda la página en aparecer.
  const pares = await Promise.all(
    PASOS.map(async (p) => {
      const { count } = await supabase
        .from(p.tabla)
        .select("*", { count: "exact", head: true })
        .eq("paciente_id", id);

      return [p.clave, count ?? 0] as const;
    }),
  );

  const conteos = Object.fromEntries(pares) as Record<ClavePaso, number>;

  return (
    <div className="space-y-8">
      <header className="space-y-5">
        <Volver href={`/pacientes/${id}`}>{paciente.nombre_completo}</Volver>

        <div className="flex flex-wrap items-center gap-x-3 gap-y-2">
          <h1 className="text-2xl font-semibold tracking-tight sm:text-3xl">
            {paciente.nombre_completo}
          </h1>
          <EstadoPacienteBadge estado={paciente.estado} />
        </div>

        <PasosNav base={`/pacientes/${id}/atender`} conteos={conteos} />
      </header>

      {paciente.estado !== "activo" && (
        <Alert className="border-accent-foreground/15 bg-accent/50">
          <AlertTitle>
            {paciente.estado === "pendiente"
              ? "Todavía no está aprobado"
              : "Está dado de baja"}
          </AlertTitle>
          <AlertDescription className="leading-relaxed">
            Podés cargarle cosas igual, pero no las va a ver hasta que la cuenta
            esté activa.
          </AlertDescription>
        </Alert>
      )}

      {children}
    </div>
  );
}
