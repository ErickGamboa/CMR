import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

/**
 * Un campo de formulario con su etiqueta y su ayuda.
 *
 * Existe para que todos los formularios del sitio tengan el mismo espaciado y
 * la ayuda quede atada al input con `aria-describedby` sin que haya que
 * acordarse en cada uno.
 */
export function Campo({
  id,
  etiqueta,
  tipo = "text",
  ayuda,
  sufijo,
  requerido = false,
  ...resto
}: {
  id: string;
  etiqueta: string;
  tipo?: string;
  ayuda?: string;
  /** Unidad que va pegada al campo: "kg", "%". */
  sufijo?: string;
  requerido?: boolean;
} & Omit<React.ComponentProps<typeof Input>, "id" | "type">) {
  return (
    <div className="space-y-2">
      <Label htmlFor={id}>
        {etiqueta}
        {sufijo && (
          <span className="ml-1 font-normal text-muted-foreground">
            ({sufijo})
          </span>
        )}
      </Label>
      <Input
        id={id}
        name={id}
        type={tipo}
        required={requerido}
        aria-describedby={ayuda ? `${id}-ayuda` : undefined}
        {...resto}
      />
      {ayuda && (
        <p id={`${id}-ayuda`} className="text-xs text-muted-foreground">
          {ayuda}
        </p>
      )}
    </div>
  );
}
