import { notFound } from "next/navigation";

import { EstadoPacienteBadge } from "@/components/estado-paciente";
import { Volver } from "@/components/volver";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { pasosDeLaConsulta } from "@/lib/consultas";
import { COLUMNAS_PACIENTE, type Paciente } from "@/lib/pacientes";
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

  const [{ data }, hechos] = await Promise.all([
    supabase
      .from("pacientes")
      .select(COLUMNAS_PACIENTE)
      .eq("user_id", id)
      .maybeSingle(),
    // Lo palomeado es lo de **esta** consulta, no lo que el paciente tenga
    // cargado de antes: a la segunda visita eso dejaba los siete pasos en
    // verde antes de empezar.
    pasosDeLaConsulta(id),
  ]);

  const paciente = data as unknown as Paciente | null;
  if (!paciente) notFound();

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

        <PasosNav base={`/pacientes/${id}/atender`} hechos={[...hechos]} />
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
