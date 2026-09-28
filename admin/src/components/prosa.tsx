/**
 * La tipografía de las páginas de texto largo.
 *
 * Las dos páginas públicas —privacidad y soporte— son documentos que alguien
 * de la App Store va a leer entero, así que comparten medidas: una sola
 * columna angosta, interlineado alto y jerarquía clara entre título, apartado
 * y párrafo. Va acá y no en cada página para que no se despeguen con el
 * tiempo.
 */

export function Titulo({
  children,
  actualizado,
}: {
  children: React.ReactNode;
  actualizado?: string;
}) {
  return (
    <header className="space-y-3 border-b pb-8">
      <h1 className="text-3xl font-semibold tracking-tight text-balance sm:text-4xl">
        {children}
      </h1>
      {actualizado && (
        <p className="text-sm text-muted-foreground">
          Última actualización: {actualizado}
        </p>
      )}
    </header>
  );
}

export function Seccion({
  titulo,
  children,
}: {
  titulo: string;
  children: React.ReactNode;
}) {
  return (
    <section className="space-y-3">
      <h2 className="text-lg font-semibold tracking-tight">{titulo}</h2>
      {children}
    </section>
  );
}

export function Parrafo({ children }: { children: React.ReactNode }) {
  return <p className="leading-relaxed text-muted-foreground">{children}</p>;
}

export function Lista({ children }: { children: React.ReactNode }) {
  return (
    <ul className="list-disc space-y-1.5 pl-5 leading-relaxed text-muted-foreground marker:text-muted-foreground/50">
      {children}
    </ul>
  );
}

/** El cuerpo entero, con el aire entre apartados. */
export function Prosa({ children }: { children: React.ReactNode }) {
  return <div className="space-y-10">{children}</div>;
}

export function Correo({ correo }: { correo: string }) {
  return (
    <a
      href={`mailto:${correo}`}
      className="font-medium text-foreground underline underline-offset-4"
    >
      {correo}
    </a>
  );
}
