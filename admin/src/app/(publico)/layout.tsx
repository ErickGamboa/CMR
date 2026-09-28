import type { Metadata } from "next";
import Link from "next/link";

import { Logo } from "@/components/logo";

/**
 * El marco de las páginas que ve cualquiera: privacidad y soporte.
 *
 * Estas dos sí tienen que ser públicas e indexables, al revés que el resto del
 * sitio: la App Store y Google Play exigen una URL abierta para la política de
 * privacidad, y no aceptan un PDF ni un `mailto:`.
 */
export const metadata: Metadata = {
  robots: { index: true, follow: true },
};

export default function LayoutPublico({ children }: LayoutProps<"/"> ) {
  return (
    <div className="flex min-h-dvh flex-col bg-background">
      <header className="border-b">
        <div className="mx-auto flex max-w-3xl items-center justify-between gap-4 px-4 py-4 sm:px-6">
          <Link href="/" aria-label="Inicio">
            <Logo variante="completo" alto={44} />
          </Link>
          <nav className="flex gap-5 text-sm text-muted-foreground">
            <Link
              href="/privacidad"
              className="underline-offset-4 transition-colors hover:text-foreground hover:underline"
            >
              Privacidad
            </Link>
            <Link
              href="/soporte"
              className="underline-offset-4 transition-colors hover:text-foreground hover:underline"
            >
              Soporte
            </Link>
            {/* La vuelta: desde acá se llega al login sin tener que adivinar
                que el logo es un enlace. */}
            <Link
              href="/"
              className="underline-offset-4 transition-colors hover:text-foreground hover:underline"
            >
              Entrar
            </Link>
          </nav>
        </div>
      </header>

      <main className="mx-auto w-full max-w-3xl flex-1 px-4 py-10 sm:px-6 sm:py-14">
        {children}
      </main>

      <footer className="border-t">
        <div className="mx-auto max-w-3xl px-4 py-6 text-xs text-muted-foreground sm:px-6">
          Clínica COSME - CMR · Control Metabólico y Regenerativo
        </div>
      </footer>
    </div>
  );
}
