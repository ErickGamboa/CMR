import type { Metadata } from "next";
import Link from "next/link";

import { buttonVariants } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  COLOR_ESTADO,
  COLUMNAS_PACIENTE,
  ETIQUETA_ESTADO,
  type Paciente,
} from "@/lib/pacientes";
import { clienteServidor } from "@/lib/supabase/servidor";

export const metadata: Metadata = { title: "Pacientes · CMR" };

export default async function PaginaPacientes() {
  const supabase = await clienteServidor();

  // Sin filtro por doctor: la política de RLS ya decide qué se puede ver, y
  // repetir la regla acá sería tener que mantenerla en dos lugares.
  const { data, error } = await supabase
    .from("pacientes")
    .select(COLUMNAS_PACIENTE)
    .order("apellidos", { ascending: true })
    .order("nombre", { ascending: true });

  if (error) {
    return <Aviso titulo="No pudimos cargar la lista">{error.message}</Aviso>;
  }

  const pacientes = (data ?? []) as unknown as Paciente[];
  // Los que se registraron solos van arriba: son los que piden una decisión.
  const pendientes = pacientes.filter((p) => p.estado === "pendiente");
  const resto = pacientes.filter((p) => p.estado !== "pendiente");

  // El botón va también acá, y no solo en el encabezado de la lista: sin
  // pacientes no hay encabezado, y quedaría un texto diciendo "podés crearle
  // la cuenta vos" sin nada dónde hacer clic.
  if (pacientes.length === 0) {
    return (
      <div className="space-y-4">
        <Aviso titulo="Todavía no hay pacientes">
          Cuando alguien se registre desde la app va a aparecer acá esperando
          tu aprobación. También podés crearle la cuenta vos.
        </Aviso>
        <Link href="/pacientes/nuevo" className={buttonVariants()}>
          Nuevo paciente
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Pacientes</h1>
          <p className="text-sm text-muted-foreground">
            {pacientes.length === 1
              ? "1 paciente"
              : `${pacientes.length} pacientes`}
            {pendientes.length > 0 &&
              ` · ${pendientes.length} esperando aprobación`}
          </p>
        </div>
        {/* Este Button no trae `asChild`, así que el enlace lleva las clases
            directamente: un <a> dentro de un <button> sería HTML inválido. */}
        <Link href="/pacientes/nuevo" className={buttonVariants()}>
          Nuevo paciente
        </Link>
      </div>

      {pendientes.length > 0 && (
        <section className="space-y-3">
          <div className="rounded-lg border border-accent-foreground/20 bg-accent/40 p-4">
            <h2 className="font-medium">Esperando aprobación</h2>
            <p className="mt-1 text-sm text-muted-foreground">
              Se registraron desde la app. Hasta que los apruebes no ven nada:
              ni su plan, ni el libro.
            </p>
          </div>
          <Tabla pacientes={pendientes} />
        </section>
      )}

      {resto.length > 0 && (
        <section className="space-y-3">
          {pendientes.length > 0 && (
            <h2 className="font-medium">Resto de pacientes</h2>
          )}
          <Tabla pacientes={resto} />
        </section>
      )}
    </div>
  );
}

function Tabla({ pacientes }: { pacientes: Paciente[] }) {
  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Nombre</TableHead>
          <TableHead>Cédula</TableHead>
          <TableHead>Correo</TableHead>
          <TableHead className="text-right">Estado</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {pacientes.map((p) => (
          <TableRow key={p.user_id}>
            <TableCell className="font-medium">
              <Link
                href={`/pacientes/${p.user_id}`}
                className="underline-offset-4 hover:underline"
              >
                {p.nombre_completo}
              </Link>
            </TableCell>
            <TableCell className="text-muted-foreground">
              {p.cedula ?? "—"}
            </TableCell>
            <TableCell className="text-muted-foreground">
              {p.correo ?? "—"}
            </TableCell>
            <TableCell className="text-right">
              <Estado estado={p.estado} />
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}

export function Estado({ estado }: { estado: Paciente["estado"] }) {
  return (
    <span
      className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${COLOR_ESTADO[estado]}`}
    >
      {ETIQUETA_ESTADO[estado]}
    </span>
  );
}

function Aviso({
  titulo,
  children,
}: {
  titulo: string;
  children: React.ReactNode;
}) {
  return (
    <div className="space-y-2">
      <h1 className="text-2xl font-semibold tracking-tight">{titulo}</h1>
      <p className="max-w-prose text-sm text-muted-foreground">{children}</p>
    </div>
  );
}
