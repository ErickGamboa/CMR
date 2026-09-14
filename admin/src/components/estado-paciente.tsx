import { Badge } from "@/components/ui/badge";
import { ETIQUETA_ESTADO, type EstadoPaciente } from "@/lib/pacientes";

/**
 * El estado de un paciente, siempre igual en toda la app.
 *
 * "Pendiente" va destacado y no en rojo: no es un error, es alguien esperando
 * a que lo atiendan, y es lo único de esta pantalla que pide una decisión.
 */
export function EstadoPacienteBadge({ estado }: { estado: EstadoPaciente }) {
  const estilo: Record<EstadoPaciente, string> = {
    pendiente: "border-transparent bg-accent text-accent-foreground",
    activo: "border-transparent bg-secondary text-secondary-foreground",
    inactivo: "text-muted-foreground",
  };

  return (
    <Badge
      variant={estado === "inactivo" ? "outline" : "secondary"}
      className={estilo[estado]}
    >
      {ETIQUETA_ESTADO[estado]}
    </Badge>
  );
}
