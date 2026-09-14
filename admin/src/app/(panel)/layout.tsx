import Link from "next/link";

import { salir } from "@/app/ingresar/acciones";
import { Logo } from "@/components/logo";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { doctorActual, type Doctor } from "@/lib/doctor";

/**
 * Todo lo que cuelga de acá ya pasó por dos puertas: el proxy exige sesión, y
 * este layout exige que además sea de un doctor.
 *
 * La comprobación va en el layout y no en cada página a propósito: una página
 * nueva queda protegida por existir dentro de `(panel)`, sin que nadie se
 * tenga que acordar de agregarle el chequeo.
 */
export default async function LayoutPanel({
  children,
}: {
  children: React.ReactNode;
}) {
  const doctor = await doctorActual();

  if (!doctor) return <SinPermiso />;

  return (
    <div className="flex min-h-dvh flex-col bg-muted/30">
      <Cabecera doctor={doctor} />

      <main className="mx-auto w-full max-w-5xl flex-1 px-4 py-8 sm:px-6 sm:py-10">
        {children}
      </main>

      <footer className="border-t bg-background">
        <div className="mx-auto max-w-5xl px-4 py-5 text-xs text-muted-foreground sm:px-6">
          Clínica COSME - CMR
        </div>
      </footer>
    </div>
  );
}

/**
 * Fondo claro y no azul abisal: el logo es azul sobre transparente y sobre
 * oscuro cae a 1.15:1, o sea desaparece.
 */
function Cabecera({ doctor }: { doctor: Doctor }) {
  return (
    <header className="sticky top-0 z-20 border-b bg-background/80 backdrop-blur-md">
      <div className="mx-auto flex h-16 max-w-5xl items-center gap-4 px-4 sm:gap-6 sm:px-6">
        <Link
          href="/pacientes"
          aria-label="Inicio"
          className="shrink-0 rounded-md outline-none transition-opacity hover:opacity-80 focus-visible:ring-2 focus-visible:ring-ring"
        >
          <Logo variante="marca" alto={24} prioridad />
        </Link>

        <nav className="flex items-center gap-1">
          <Link
            href="/pacientes"
            className="rounded-md px-3 py-1.5 text-sm font-medium text-muted-foreground transition-colors hover:bg-secondary hover:text-primary"
          >
            Pacientes
          </Link>
        </nav>

        <div className="ml-auto">
          <DropdownMenu>
            <DropdownMenuTrigger
              render={<Button variant="ghost" size="sm" className="gap-2" />}
            >
              <span
                aria-hidden
                className="flex size-7 items-center justify-center rounded-full bg-primary text-xs font-semibold text-primary-foreground"
              >
                {iniciales(doctor.nombre)}
              </span>
              <span className="hidden max-w-[16ch] truncate sm:inline">
                {doctor.nombre}
              </span>
            </DropdownMenuTrigger>

            <DropdownMenuContent align="end" className="w-60">
              <DropdownMenuLabel className="font-normal">
                <p className="text-sm font-medium">{doctor.nombre}</p>
                <p className="truncate text-xs text-muted-foreground">
                  {doctor.correo}
                </p>
              </DropdownMenuLabel>
              <DropdownMenuSeparator />
              {/* Un formulario y no un enlace: cerrar sesión cambia estado en
                  el servidor, y eso no va por GET. */}
              <form action={salir}>
                <DropdownMenuItem
                  render={
                    <button type="submit" className="w-full cursor-pointer" />
                  }
                >
                  Cerrar sesión
                </DropdownMenuItem>
              </form>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>
    </header>
  );
}

/** "Dr. Erick Gamboa" → "EG". Se salta los títulos y las partículas. */
function iniciales(nombre: string) {
  const saltar = new Set(["dr", "dra", "de", "del", "la", "los", "y"]);

  const letras = nombre
    .split(/\s+/)
    .map((p) => p.replace(/\./g, ""))
    .filter((p) => p.length > 0 && !saltar.has(p.toLowerCase()))
    .slice(0, 2)
    .map((p) => p[0]?.toUpperCase() ?? "");

  return letras.join("") || "·";
}

/**
 * La sesión es válida, pero no es de un doctor.
 *
 * Dice exactamente qué falta —una fila en `doctores`— porque el caso más
 * probable no es un intruso: es el propio doctor entrando con una cuenta a la
 * que todavía no le dieron de alta.
 */
function SinPermiso() {
  return (
    <main className="flex min-h-dvh items-center justify-center p-6">
      <div className="w-full max-w-md space-y-6 text-center">
        <div className="flex justify-center">
          <Logo variante="completo" alto={64} />
        </div>
        <div className="space-y-2">
          <h1 className="text-xl font-semibold tracking-tight">
            Esta cuenta no administra la clínica
          </h1>
          <p className="text-sm leading-relaxed text-muted-foreground">
            Entraste bien, pero tu cuenta no está registrada como doctor. Se da
            de alta agregando una fila en la tabla{" "}
            <code className="rounded bg-muted px-1.5 py-0.5 font-mono text-xs">
              doctores
            </code>
            .
          </p>
        </div>
        <form action={salir}>
          <Button type="submit" variant="outline">
            Cerrar sesión
          </Button>
        </form>
      </div>
    </main>
  );
}
