import Link from "next/link";

import { salir } from "@/app/ingresar/acciones";
import { Logo } from "@/components/logo";
import { Button } from "@/components/ui/button";
import { doctorActual } from "@/lib/doctor";

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
    <div className="flex min-h-dvh flex-col">
      {/* Fondo claro, no azul abisal: el logo es azul sobre transparente y
          sobre oscuro desaparece. */}
      <header className="sticky top-0 z-10 border-b bg-background/90 backdrop-blur">
        <div className="mx-auto flex max-w-6xl items-center gap-6 px-6 py-3">
          <Link href="/pacientes" aria-label="Inicio">
            <Logo variante="marca" alto={26} prioridad />
          </Link>

          <nav className="flex items-center gap-1 text-sm">
            <Enlace href="/pacientes">Pacientes</Enlace>
          </nav>

          <div className="ml-auto flex items-center gap-3">
            <div className="hidden text-right sm:block">
              <p className="text-sm font-medium leading-tight">
                {doctor.nombre}
              </p>
              <p className="text-xs text-muted-foreground leading-tight">
                {doctor.correo}
              </p>
            </div>
            <form action={salir}>
              <Button type="submit" variant="outline" size="sm">
                Salir
              </Button>
            </form>
          </div>
        </div>
      </header>

      <main className="mx-auto w-full max-w-6xl flex-1 px-6 py-8">
        {children}
      </main>

      <footer className="border-t">
        <div className="mx-auto max-w-6xl px-6 py-4 text-xs text-muted-foreground">
          Clínica COSME - CMR
        </div>
      </footer>
    </div>
  );
}

function Enlace({ href, children }: { href: string; children: string }) {
  return (
    <Link
      href={href}
      className="rounded-md px-3 py-1.5 font-medium text-muted-foreground transition-colors hover:bg-secondary hover:text-primary"
    >
      {children}
    </Link>
  );
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
      <div className="max-w-md space-y-5 text-center">
        <div className="flex justify-center">
          <Logo variante="completo" alto={72} />
        </div>
        <h1 className="text-xl font-semibold">
          Esta cuenta no administra la clínica
        </h1>
        <p className="text-sm text-muted-foreground">
          Entraste bien, pero tu cuenta no está registrada como doctor. Se da de
          alta agregando una fila en la tabla <code>doctores</code>.
        </p>
        <form action={salir}>
          <Button type="submit" variant="outline">
            Salir
          </Button>
        </form>
      </div>
    </main>
  );
}
