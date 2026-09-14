import Image from "next/image";

/**
 * Logo de CMR.
 *
 * Dos variantes, las mismas que la app:
 *   - `completo`: monograma + "Control Metabólico & Regenerativo".
 *   - `marca`: solo el monograma con la hélice.
 *
 * El arte es azul abisal sobre transparente, así que **exige fondo claro**.
 * Sobre superficie oscura el contraste cae a 1.15:1 y el logo desaparece.
 * Mientras no exista una versión invertida, no usarlo sobre fondos oscuros.
 */
const VARIANTES = {
  completo: { src: "/logo-cmr.png", proporcion: 1385 / 991 },
  marca: { src: "/logo-cmr-marca.png", proporcion: 1385 / 828 },
} as const;

export function Logo({
  variante = "completo",
  alto,
  className,
  prioridad = false,
}: {
  variante?: keyof typeof VARIANTES;
  alto: number;
  className?: string;
  prioridad?: boolean;
}) {
  const { src, proporcion } = VARIANTES[variante];
  const ancho = Math.round(alto * proporcion);

  return (
    <Image
      src={src}
      alt="CMR — Control Metabólico & Regenerativo"
      width={ancho}
      height={alto}
      className={className}
      // El original pesa más de un mega: dejar que Next lo redimensione y lo
      // sirva en un formato moderno, en vez de mandarlo tal cual.
      priority={prioridad}
    />
  );
}
