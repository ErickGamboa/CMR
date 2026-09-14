import Link from "next/link";
import { notFound } from "next/navigation";

import {
  COLOR_ESTADO,
  COLUMNAS_PACIENTE,
  ETIQUETA_ESTADO,
  type Paciente,
} from "@/lib/pacientes";
import { clienteServidor } from "@/lib/supabase/servidor";

import { Acceso } from "./acceso";
import { BotonesEstado } from "./botones-estado";
import { FormularioFicha } from "./ficha";

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
  return { title: `${paciente?.nombre_completo ?? "Paciente"} · CMR` };
}

export default async function PaginaPaciente({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const paciente = await buscar(id);

  // Sin fila puede ser que no exista o que RLS no deje verla. Las dos cosas se
  // muestran igual: decir "existe pero no podés verlo" ya sería filtrar algo.
  if (!paciente) notFound();

  return (
    <div className="space-y-8">
      <div className="space-y-3">
        <Link
          href="/pacientes"
          className="text-sm text-muted-foreground hover:text-foreground"
        >
          ← Pacientes
        </Link>

        <div className="flex flex-wrap items-center gap-3">
          <h1 className="text-2xl font-semibold tracking-tight">
            {paciente.nombre_completo}
          </h1>
          <span
            className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${COLOR_ESTADO[paciente.estado]}`}
          >
            {ETIQUETA_ESTADO[paciente.estado]}
          </span>
        </div>

        <p className="text-sm text-muted-foreground">
          {paciente.correo ?? "Sin correo registrado"}
        </p>
      </div>

      {paciente.estado === "pendiente" && (
        <div className="rounded-lg border border-accent-foreground/20 bg-accent/40 p-4">
          <h2 className="font-medium">Se registró desde la app</h2>
          <p className="mt-1 max-w-prose text-sm text-muted-foreground">
            Todavía no ve nada: ni su plan, ni sus citas, ni el libro.
            Comprobá que los datos coincidan con los de la clínica antes de
            aprobarlo.
          </p>
        </div>
      )}

      <section className="space-y-3">
        <h2 className="text-sm font-medium text-muted-foreground">
          Estado de la cuenta
        </h2>
        <BotonesEstado id={paciente.user_id} estado={paciente.estado} />
      </section>

      <section className="space-y-3">
        <h2 className="text-sm font-medium text-muted-foreground">
          Acceso a la app
        </h2>
        <Acceso id={paciente.user_id} correo={paciente.correo} />
      </section>

      <section className="space-y-4">
        <h2 className="text-sm font-medium text-muted-foreground">Datos</h2>
        <FormularioFicha paciente={paciente} />
      </section>
    </div>
  );
}
