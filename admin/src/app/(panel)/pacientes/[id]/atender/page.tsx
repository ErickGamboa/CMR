import Link from "next/link";
import { notFound } from "next/navigation";

import { EstadoPacienteBadge } from "@/components/estado-paciente";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { COLUMNAS_PACIENTE, type Paciente } from "@/lib/pacientes";
import { clienteServidor } from "@/lib/supabase/servidor";

/**
 * Lo que el doctor le manda a un paciente, todo en un lugar.
 *
 * Por ahora es el índice: cada bloque dice cuántas cosas tiene cargadas hoy y
 * queda listo para colgarle su pantalla. El conteo no es decorativo —es lo
 * primero que uno quiere saber al sentarse a atender a alguien: qué le falta.
 */
type Modulo = {
  clave: string;
  titulo: string;
  detalle: string;
  tabla: string;
};

const MODULOS: Modulo[] = [
  {
    clave: "citas",
    titulo: "Citas",
    detalle: "Agenda médica y de enfermería.",
    tabla: "citas",
  },
  {
    clave: "mediciones",
    titulo: "Mediciones",
    detalle: "Peso, grasa y músculo de cada control.",
    tabla: "mediciones",
  },
  {
    clave: "laboratorios",
    titulo: "Laboratorios",
    detalle: "Exámenes con sus valores y referencias.",
    tabla: "laboratorios",
  },
  {
    clave: "recomendaciones",
    titulo: "Recomendaciones",
    detalle: "Indicaciones escritas que ve en la app.",
    tabla: "recomendaciones",
  },
  {
    clave: "prescripciones",
    titulo: "Suplementos, péptidos y medicamentos",
    detalle: "Lo recetado, con dosis y frecuencia.",
    tabla: "prescripciones",
  },
  {
    clave: "plan",
    titulo: "Plan de alimentación",
    detalle: "Intercambios por tiempo de comida.",
    tabla: "planes_alimentacion",
  },
  {
    clave: "mapeo",
    titulo: "Mapeo",
    detalle: "Presión y glisemia que anota el paciente.",
    tabla: "mapeo_registros",
  },
];

async function buscar(id: string) {
  const supabase = await clienteServidor();
  const { data } = await supabase
    .from("pacientes")
    .select(COLUMNAS_PACIENTE)
    .eq("user_id", id)
    .maybeSingle();

  return data as unknown as Paciente | null;
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const paciente = await buscar(id);
  return { title: `Atender a ${paciente?.nombre ?? "paciente"} · CMR` };
}

export default async function PaginaAtender({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const paciente = await buscar(id);
  if (!paciente) notFound();

  const supabase = await clienteServidor();

  // Los conteos salen en paralelo: son siete consultas chiquitas y esperarlas
  // en fila multiplicaría por siete lo que tarda la página en aparecer.
  const conteos = await Promise.all(
    MODULOS.map(async (m) => {
      const { count } = await supabase
        .from(m.tabla)
        .select("*", { count: "exact", head: true })
        .eq("paciente_id", id);

      return [m.clave, count ?? 0] as const;
    }),
  );

  const porModulo = Object.fromEntries(conteos);

  return (
    <div className="animate-in fade-in duration-300 space-y-8">
      <header className="space-y-4">
        <Link
          href={`/pacientes/${id}`}
          className="inline-flex items-center gap-1 text-sm text-muted-foreground transition-colors hover:text-foreground"
        >
          <span aria-hidden>←</span> {paciente.nombre_completo}
        </Link>

        <div className="flex flex-wrap items-center gap-x-3 gap-y-2">
          <h1 className="text-3xl font-semibold tracking-tight">Atender</h1>
          <EstadoPacienteBadge estado={paciente.estado} />
        </div>

        <p className="max-w-prose text-sm leading-relaxed text-muted-foreground">
          Todo lo que {paciente.nombre} ve en la app sale de acá. El número es
          lo que ya tiene cargado.
        </p>
      </header>

      {paciente.estado !== "activo" && (
        <Alert className="border-accent-foreground/15 bg-accent/50">
          <AlertTitle>
            {paciente.estado === "pendiente"
              ? "Todavía no está aprobado"
              : "Está dado de baja"}
          </AlertTitle>
          <AlertDescription className="leading-relaxed">
            Podés cargarle cosas igual, pero no las va a ver hasta que la
            cuenta esté activa.
          </AlertDescription>
        </Alert>
      )}

      <div className="grid gap-4 sm:grid-cols-2">
        {MODULOS.map((m) => (
          <Card key={m.clave} className="transition-colors">
            <CardHeader>
              <CardTitle className="flex items-start justify-between gap-3 text-base">
                <span className="leading-snug">{m.titulo}</span>
                <span className="shrink-0 rounded-full bg-secondary px-2.5 py-0.5 text-sm font-semibold tabular-nums text-secondary-foreground">
                  {porModulo[m.clave]}
                </span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="text-sm leading-relaxed text-muted-foreground">
                {m.detalle}
              </p>
              <p className="text-xs text-muted-foreground/80">
                Pantalla pendiente
              </p>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
