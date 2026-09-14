import Link from "next/link";
import { notFound } from "next/navigation";

import { EstadoPacienteBadge } from "@/components/estado-paciente";
import { Volver } from "@/components/volver";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { buttonVariants } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { COLUMNAS_PACIENTE, type Paciente } from "@/lib/pacientes";
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
    <div className="animate-in fade-in duration-300 space-y-8">
      <header className="space-y-4">
        <Volver href="/pacientes">Pacientes</Volver>

        <div className="flex flex-wrap items-start justify-between gap-4">
          <div className="space-y-2">
            <div className="flex flex-wrap items-center gap-x-3 gap-y-2">
              <h1 className="text-3xl font-semibold tracking-tight">
                {paciente.nombre_completo}
              </h1>
              <EstadoPacienteBadge estado={paciente.estado} />
            </div>
            <p className="text-sm text-muted-foreground">
              {paciente.correo ?? "Sin correo registrado"}
            </p>
          </div>

          {/* Lo que el doctor viene a hacer casi siempre. Esta pantalla es
              para corregir datos; atender es el trabajo. */}
          <Link
            href={`/pacientes/${paciente.user_id}/atender`}
            className={buttonVariants({ className: "w-full sm:w-auto" })}
          >
            Atender
          </Link>
        </div>
      </header>

      {paciente.estado === "pendiente" && (
        <Alert className="border-accent-foreground/15 bg-accent/50">
          <AlertTitle>Se registró desde la app</AlertTitle>
          <AlertDescription className="leading-relaxed">
            Todavía no ve nada: ni su plan, ni sus citas, ni el libro. Comprobá
            que los datos coincidan con los de la clínica antes de aprobarlo.
          </AlertDescription>
        </Alert>
      )}

      <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_20rem] lg:items-start">
        <Card className="order-2 lg:order-1">
          <CardHeader>
            <CardTitle>Datos</CardTitle>
          </CardHeader>
          <CardContent>
            <FormularioFicha paciente={paciente} />
          </CardContent>
        </Card>

        <div className="order-1 space-y-6 lg:order-2">
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Estado de la cuenta</CardTitle>
            </CardHeader>
            <CardContent>
              <BotonesEstado id={paciente.user_id} estado={paciente.estado} />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Acceso a la app</CardTitle>
            </CardHeader>
            <CardContent>
              <Acceso id={paciente.user_id} correo={paciente.correo} />
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
