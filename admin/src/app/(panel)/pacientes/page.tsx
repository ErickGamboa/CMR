import type { Metadata } from "next";
import Link from "next/link";

import { buttonVariants } from "@/components/ui/button";
import { COLUMNAS_PACIENTE, type Paciente } from "@/lib/pacientes";
import { clienteServidor } from "@/lib/supabase/servidor";

import { ListaPacientes } from "./lista";

export const metadata: Metadata = { title: "Pacientes · CMR" };

export default async function PaginaPacientes() {
  const supabase = await clienteServidor();

  // Se traen todos de una: el filtro y la búsqueda son cosa del navegador, y
  // con cientos de pacientes esto pesa poco. Cuando sean miles, habrá que
  // paginar y mover la búsqueda al servidor.
  //
  // Sin filtro por doctor: la política de RLS ya decide qué se puede ver, y
  // repetir la regla acá sería tener que mantenerla en dos lugares.
  const { data, error } = await supabase
    .from("pacientes")
    .select(COLUMNAS_PACIENTE)
    .order("apellidos", { ascending: true })
    .order("nombre", { ascending: true });

  if (error) {
    return (
      <Vacio
        titulo="No pudimos cargar la lista"
        detalle={error.message}
        conBoton={false}
      />
    );
  }

  const pacientes = (data ?? []) as unknown as Paciente[];

  if (pacientes.length === 0) {
    return (
      <Vacio
        titulo="Todavía no hay pacientes"
        detalle="Cuando alguien se registre desde la app va a aparecer acá esperando tu aprobación. También podés crearle la cuenta vos."
      />
    );
  }

  return (
    <div className="animate-in fade-in duration-300 space-y-8">
      <header className="flex flex-wrap items-end justify-between gap-4">
        <div className="space-y-1">
          <h1 className="text-3xl font-semibold tracking-tight">Pacientes</h1>
          <p className="text-sm text-muted-foreground">
            {pacientes.length === 1
              ? "1 paciente en total"
              : `${pacientes.length} pacientes en total`}
          </p>
        </div>
        <Link
          href="/pacientes/nuevo"
          className={buttonVariants({ className: "w-full sm:w-auto" })}
        >
          Nuevo paciente
        </Link>
      </header>

      <ListaPacientes pacientes={pacientes} />
    </div>
  );
}

/**
 * Vacío y error comparten forma: centrados, porque no compiten con nada más
 * en la pantalla y centrar los deja donde el ojo ya está.
 */
function Vacio({
  titulo,
  detalle,
  conBoton = true,
}: {
  titulo: string;
  detalle: string;
  conBoton?: boolean;
}) {
  return (
    <div className="animate-in fade-in duration-300 flex min-h-[50vh] items-center justify-center">
      <div className="max-w-md space-y-5 text-center">
        <div className="space-y-2">
          <h1 className="text-2xl font-semibold tracking-tight">{titulo}</h1>
          <p className="text-sm leading-relaxed text-muted-foreground">
            {detalle}
          </p>
        </div>
        {conBoton && (
          <Link href="/pacientes/nuevo" className={buttonVariants()}>
            Nuevo paciente
          </Link>
        )}
      </div>
    </div>
  );
}
