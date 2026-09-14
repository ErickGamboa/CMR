"use client";

import { Search, X } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useMemo, useState } from "react";

import { EstadoPacienteBadge } from "@/components/estado-paciente";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type { EstadoPaciente, Paciente } from "@/lib/pacientes";

/**
 * Quita acentos y pasa a minúsculas.
 *
 * Sin esto, buscar "maria" no encuentra a "María", que es justo lo que uno
 * escribe cuando tiene prisa.
 */
function normalizar(texto: string) {
  return texto
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase();
}

const PESTANAS: { valor: EstadoPaciente; etiqueta: string }[] = [
  { valor: "activo", etiqueta: "Activos" },
  { valor: "pendiente", etiqueta: "Esperando aprobación" },
  { valor: "inactivo", etiqueta: "Inactivos" },
];

/**
 * La lista con filtro por estado y búsqueda.
 *
 * Filtra en el navegador y no contra el servidor a propósito: la lista entera
 * ya viene cargada, y con cientos de pacientes pesa poco. Ir al servidor por
 * cada tecla haría que escribir "mar" se sienta lento, que es exactamente lo
 * contrario de lo que un buscador tiene que dar.
 */
export function ListaPacientes({ pacientes }: { pacientes: Paciente[] }) {
  // Arranca en activos: es la lista de trabajo del día. Los pendientes llevan
  // un contador en su pestaña para que no pasen desapercibidos.
  const [estado, setEstado] = useState<EstadoPaciente>("activo");
  const [consulta, setConsulta] = useState("");

  const porEstado = useMemo(() => {
    const mapa = { activo: 0, pendiente: 0, inactivo: 0 };
    for (const p of pacientes) mapa[p.estado]++;
    return mapa;
  }, [pacientes]);

  const visibles = useMemo(() => {
    const buscado = normalizar(consulta.trim());

    return pacientes.filter((p) => {
      if (p.estado !== estado) return false;
      if (buscado === "") return true;

      // Se busca también por cédula y correo: el doctor a veces tiene el
      // número a mano y no el nombre.
      const campos = [p.nombre_completo, p.cedula ?? "", p.correo ?? ""];
      return campos.some((c) => normalizar(c).includes(buscado));
    });
  }, [pacientes, estado, consulta]);

  return (
    <div className="space-y-5">
      <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
        <Tabs
          value={estado}
          onValueChange={(v) => setEstado(v as EstadoPaciente)}
        >
          <TabsList className="w-full lg:w-auto">
            {PESTANAS.map((p) => (
              <TabsTrigger key={p.valor} value={p.valor} className="gap-2">
                <span className="truncate">{p.etiqueta}</span>
                {porEstado[p.valor] > 0 && (
                  <Badge
                    variant={p.valor === "pendiente" ? "default" : "secondary"}
                    className="px-1.5 py-0 text-[11px] tabular-nums"
                  >
                    {porEstado[p.valor]}
                  </Badge>
                )}
              </TabsTrigger>
            ))}
          </TabsList>
        </Tabs>

        <div className="relative lg:w-72">
          <Search
            aria-hidden
            className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
          />
          <Input
            type="search"
            value={consulta}
            onChange={(e) => setConsulta(e.target.value)}
            placeholder="Buscar por nombre, cédula o correo"
            aria-label="Buscar paciente"
            className="pl-9 pr-9"
          />
          {consulta !== "" && (
            <button
              type="button"
              onClick={() => setConsulta("")}
              aria-label="Limpiar búsqueda"
              className="absolute right-2 top-1/2 -translate-y-1/2 rounded-md p-1 text-muted-foreground transition-colors hover:text-foreground"
            >
              <X className="size-4" />
            </button>
          )}
        </div>
      </div>

      {estado === "pendiente" && porEstado.pendiente > 0 && (
        <div className="rounded-xl border border-accent-foreground/15 bg-accent/50 p-4">
          <p className="text-sm leading-relaxed text-muted-foreground">
            Se registraron desde la app. Hasta que los apruebes no ven nada: ni
            su plan, ni sus citas, ni el libro.
          </p>
        </div>
      )}

      {visibles.length === 0 ? (
        <SinResultados
          consulta={consulta}
          estado={estado}
          onLimpiar={() => setConsulta("")}
        />
      ) : (
        <Filas pacientes={visibles} />
      )}
    </div>
  );
}

/**
 * La misma lista en dos formas.
 *
 * Una tabla de cuatro columnas en un teléfono obliga a hacer scroll lateral
 * para leer una fila, así que abajo de `md` cada paciente es una tarjeta.
 */
function Filas({ pacientes }: { pacientes: Paciente[] }) {
  const router = useRouter();

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
              <TableRow
                key={p.user_id}
                // Toda la fila abre la ficha, no solo el nombre. El enlace del
                // nombre se queda igual: es lo que hace que funcione con
                // teclado, con lector de pantalla y con "abrir en otra pestaña".
                onClick={() => router.push(`/pacientes/${p.user_id}`)}
                className="cursor-pointer transition-colors"
              >
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

function SinResultados({
  consulta,
  estado,
  onLimpiar,
}: {
  consulta: string;
  estado: EstadoPaciente;
  onLimpiar: () => void;
}) {
  const buscando = consulta.trim() !== "";

  const vacio: Record<EstadoPaciente, string> = {
    activo: "No hay pacientes activos.",
    pendiente: "Nadie está esperando aprobación.",
    inactivo: "No hay pacientes dados de baja.",
  };

  return (
    <div className="flex min-h-[30vh] items-center justify-center rounded-xl border border-dashed">
      <div className="max-w-sm space-y-3 px-6 py-10 text-center">
        <p className="text-sm text-muted-foreground">
          {buscando
            ? `No encontramos a nadie con “${consulta.trim()}” en esta lista.`
            : vacio[estado]}
        </p>
        {buscando && (
          <button
            type="button"
            onClick={onLimpiar}
            className="text-sm font-medium underline underline-offset-4 transition-colors hover:text-primary"
          >
            Limpiar la búsqueda
          </button>
        )}
      </div>
    </div>
  );
}
