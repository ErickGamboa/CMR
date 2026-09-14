import type { Metadata } from "next";
import Link from "next/link";

import { EstadoPacienteBadge } from "@/components/estado-paciente";
import { buttonVariants } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { COLUMNAS_PACIENTE, type Paciente } from "@/lib/pacientes";
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
    return (
      <Vacio
        titulo="No pudimos cargar la lista"
        detalle={error.message}
        conBoton={false}
      />
    );
  }

  const pacientes = (data ?? []) as unknown as Paciente[];
  // Los que se registraron solos van arriba: son los que piden una decisión.
  const pendientes = pacientes.filter((p) => p.estado === "pendiente");
  const resto = pacientes.filter((p) => p.estado !== "pendiente");

  if (pacientes.length === 0) {
    return (
      <Vacio
        titulo="Todavía no hay pacientes"
        detalle="Cuando alguien se registre desde la app va a aparecer acá esperando tu aprobación. También podés crearle la cuenta vos."
      />
    );
  }

  return (
    <div className="animate-in fade-in duration-300 space-y-10">
      <header className="flex flex-wrap items-end justify-between gap-4">
        <div className="space-y-1">
          <h1 className="text-3xl font-semibold tracking-tight">Pacientes</h1>
          <p className="text-sm text-muted-foreground">
            {pacientes.length === 1
              ? "1 paciente"
              : `${pacientes.length} pacientes`}
            {pendientes.length > 0 &&
              ` · ${pendientes.length} esperando aprobación`}
          </p>
        </div>
        <Link
          href="/pacientes/nuevo"
          className={buttonVariants({ className: "w-full sm:w-auto" })}
        >
          Nuevo paciente
        </Link>
      </header>

      {pendientes.length > 0 && (
        <section className="space-y-4">
          <div className="rounded-xl border border-accent-foreground/15 bg-accent/50 p-5">
            <h2 className="font-medium">Esperando aprobación</h2>
            <p className="mt-1 max-w-prose text-sm leading-relaxed text-muted-foreground">
              Se registraron desde la app. Hasta que los apruebes no ven nada:
              ni su plan, ni sus citas, ni el libro.
            </p>
          </div>
          <Lista pacientes={pendientes} />
        </section>
      )}

      {resto.length > 0 && (
        <section className="space-y-4">
          {pendientes.length > 0 && (
            <h2 className="text-lg font-medium tracking-tight">
              Resto de pacientes
            </h2>
          )}
          <Lista pacientes={resto} />
        </section>
      )}
    </div>
  );
}

/**
 * La misma lista en dos formas.
 *
 * Una tabla de cuatro columnas en un teléfono obliga a hacer scroll lateral
 * para leer una fila, así que abajo de `md` cada paciente es una tarjeta con
 * sus datos apilados.
 */
function Lista({ pacientes }: { pacientes: Paciente[] }) {
  return (
    <>
      <Card className="hidden overflow-hidden p-0 md:block">
        <Table>
          <TableHeader>
            <TableRow className="hover:bg-transparent">
              <TableHead className="pl-6">Nombre</TableHead>
              <TableHead>Cédula</TableHead>
              <TableHead>Correo</TableHead>
              <TableHead className="pr-6 text-right">Estado</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {pacientes.map((p) => (
              <TableRow key={p.user_id} className="transition-colors">
                <TableCell className="pl-6 font-medium">
                  <Link
                    href={`/pacientes/${p.user_id}`}
                    className="underline-offset-4 outline-none hover:underline focus-visible:underline"
                  >
                    {p.nombre_completo}
                  </Link>
                </TableCell>
                <TableCell className="font-mono text-sm text-muted-foreground">
                  {p.cedula ?? "—"}
                </TableCell>
                <TableCell className="text-muted-foreground">
                  {p.correo ?? "—"}
                </TableCell>
                <TableCell className="pr-6 text-right">
                  <EstadoPacienteBadge estado={p.estado} />
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Card>

      <div className="grid gap-3 md:hidden">
        {pacientes.map((p) => (
          <Link
            key={p.user_id}
            href={`/pacientes/${p.user_id}`}
            className="rounded-xl outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <Card className="transition-colors hover:border-primary/30">
              <CardContent className="space-y-3">
                <div className="flex items-start justify-between gap-3">
                  <span className="font-medium leading-snug">
                    {p.nombre_completo}
                  </span>
                  <EstadoPacienteBadge estado={p.estado} />
                </div>
                <dl className="space-y-1 text-sm text-muted-foreground">
                  <Dato etiqueta="Cédula" valor={p.cedula} mono />
                  <Dato etiqueta="Correo" valor={p.correo} />
                </dl>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>
    </>
  );
}

function Dato({
  etiqueta,
  valor,
  mono = false,
}: {
  etiqueta: string;
  valor: string | null;
  mono?: boolean;
}) {
  return (
    <div className="flex gap-2">
      <dt className="w-16 shrink-0">{etiqueta}</dt>
      <dd className={`truncate ${mono ? "font-mono text-xs" : ""}`}>
        {valor ?? "—"}
      </dd>
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
