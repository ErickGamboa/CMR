"use client";

import { Check, Pencil, Plus, Search, X } from "lucide-react";
import { useMemo, useState, useTransition } from "react";

import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  armarPrescripcion,
  faltantes,
  filtrar,
  valoresIniciales,
  type CampoLibre,
  type CampoPlantilla,
  type DatosAgregar,
  type Plantilla,
  type Valores,
} from "@/lib/indicaciones";

import { Frase } from "./frase";

export type Grupo = {
  clave: string;
  titulo: string;
  plantillas: Plantilla[];
};

/**
 * El catálogo, para tocar.
 *
 * La consulta dura lo que dura, y escribir "Creatina Monohidratada 5 g en
 * cualquier momento del día" por centésima vez no es parte de atender a
 * nadie. Acá el doctor busca, toca la ficha, aprieta la dosis y ya: lo que no
 * tiene nada que llenar se agrega de un solo clic.
 */
export function SelectorIndicaciones({
  grupos,
  modo,
  accion,
  camposLibres,
}: {
  grupos: Grupo[];
  /** Cómo se dibuja la vista previa: como tarjeta de la app o como texto. */
  modo: "prescripcion" | "recomendacion";
  accion: (datos: DatosAgregar) => Promise<{ error: string | null }>;
  /** Los campos que se abren en blanco cuando la plantilla es libre. */
  camposLibres: CampoLibre[];
}) {
  const [grupo, setGrupo] = useState(grupos[0]?.clave ?? "");
  const [busqueda, setBusqueda] = useState("");
  const [abierta, setAbierta] = useState<Plantilla | null>(null);
  const [valores, setValores] = useState<Valores>({});
  const [libre, setLibre] = useState<Record<string, string>>({});
  const [error, setError] = useState<string | null>(null);
  const [recien, setRecien] = useState<string | null>(null);
  const [enCurso, empezar] = useTransition();

  const actual = grupos.find((g) => g.clave === grupo) ?? grupos[0];
  const visibles = useMemo(
    () => filtrar(actual?.plantillas ?? [], busqueda),
    [actual, busqueda],
  );

  function cerrar() {
    setAbierta(null);
    setValores({});
    setLibre({});
    setError(null);
  }

  function enviar(p: Plantilla, v: Valores, l: Record<string, string>) {
    setError(null);
    empezar(async () => {
      const r = await accion({
        plantillaId: p.id,
        valores: v,
        libre: p.libre ? l : undefined,
      });

      if (r.error) {
        setError(r.error);
        return;
      }

      cerrar();
      setRecien(p.id);
      // El visto se apaga solo: si se queda puesto, en la próxima consulta
      // parece que ese paciente ya lo tiene.
      setTimeout(() => setRecien(null), 2500);
    });
  }

  function tocar(p: Plantilla) {
    if (abierta?.id === p.id) {
      cerrar();
      return;
    }

    // Lo que no tiene nada que llenar no necesita un formulario de por medio.
    if (!p.libre && p.campos.length === 0) {
      setAbierta(null);
      enviar(p, {}, {});
      return;
    }

    setAbierta(p);
    setValores(valoresIniciales(p));
    setLibre({});
    setError(null);
  }

  return (
    <div className="space-y-5">
      {grupos.length > 1 && (
        <div
          role="tablist"
          aria-label="Tipo de indicación"
          className="inline-flex rounded-lg border bg-muted/40 p-1"
        >
          {grupos.map((g) => (
            <button
              key={g.clave}
              role="tab"
              type="button"
              aria-selected={g.clave === grupo}
              onClick={() => {
                setGrupo(g.clave);
                cerrar();
              }}
              className={`rounded-md px-3 py-1.5 text-sm font-medium transition-colors ${
                g.clave === grupo
                  ? "bg-background text-foreground shadow-xs"
                  : "text-muted-foreground hover:text-foreground"
              }`}
            >
              {g.titulo}
              <span className="ml-1.5 text-xs font-normal text-muted-foreground">
                {g.plantillas.length}
              </span>
            </button>
          ))}
        </div>
      )}

      <div className="relative">
        <Search
          aria-hidden
          className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
        />
        <Input
          type="search"
          value={busqueda}
          onChange={(e) => setBusqueda(e.target.value)}
          placeholder="Buscar…"
          aria-label="Buscar en el catálogo"
          className="pl-9"
        />
      </div>

      {visibles.length === 0 ? (
        <p className="py-8 text-center text-sm text-muted-foreground">
          Nada con ese nombre.
        </p>
      ) : (
        <div className="grid gap-2 sm:grid-cols-2 xl:grid-cols-3">
          {visibles.map((p) => (
            <Ficha
              key={p.id}
              plantilla={p}
              abierta={abierta?.id === p.id}
              recien={recien === p.id}
              ocupado={enCurso}
              onTocar={() => tocar(p)}
            />
          ))}
        </div>
      )}

      {abierta && (
        <Editor
          // Remontar al cambiar de ficha: los controles guardan si el doctor
          // apretó "Otro", y dos plantillas distintas comparten la clave
          // "dosis", así que sin llave heredarían ese estado.
          key={abierta.id}
          plantilla={abierta}
          valores={valores}
          setValores={setValores}
          libre={libre}
          setLibre={setLibre}
          camposLibres={camposLibres}
          modo={modo}
          error={error}
          ocupado={enCurso}
          onCancelar={cerrar}
          onAgregar={() => enviar(abierta, valores, libre)}
        />
      )}

      {error && !abierta && (
        <Alert variant="destructive" className="animate-in fade-in">
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// La ficha
// ---------------------------------------------------------------------------

function Ficha({
  plantilla,
  abierta,
  recien,
  ocupado,
  onTocar,
}: {
  plantilla: Plantilla;
  abierta: boolean;
  recien: boolean;
  ocupado: boolean;
  onTocar: () => void;
}) {
  const llenar = plantilla.libre || plantilla.campos.length > 0;

  return (
    <button
      type="button"
      onClick={onTocar}
      disabled={ocupado}
      aria-expanded={llenar ? abierta : undefined}
      className={`group flex items-center gap-3 rounded-lg border px-3.5 py-3 text-left transition-all duration-200 disabled:opacity-60 ${
        abierta
          ? "border-primary bg-primary/5 shadow-xs"
          : "hover:border-primary/40 hover:bg-accent/50"
      }`}
    >
      <span className="min-w-0 flex-1">
        <span className="block truncate text-sm font-medium leading-snug">
          {plantilla.nombre}
        </span>
        <span className="mt-0.5 block text-xs text-muted-foreground">
          {recien
            ? "Agregado"
            : plantilla.libre
              ? "Se escribe a mano"
              : llenar
                ? plantilla.campos.map((c) => c.etiqueta).join(" · ")
                : "Un clic"}
        </span>
      </span>

      <span
        aria-hidden
        className={`flex size-7 shrink-0 items-center justify-center rounded-full transition-colors ${
          recien
            ? "bg-primary text-primary-foreground"
            : abierta
              ? "bg-primary/15 text-primary"
              : "bg-muted text-muted-foreground group-hover:bg-primary/10 group-hover:text-primary"
        }`}
      >
        {recien ? (
          <Check className="size-4" />
        ) : llenar ? (
          <Pencil className="size-3.5" />
        ) : (
          <Plus className="size-4" />
        )}
      </span>
    </button>
  );
}

// ---------------------------------------------------------------------------
// El panel que se abre
// ---------------------------------------------------------------------------

function Editor({
  plantilla,
  valores,
  setValores,
  libre,
  setLibre,
  camposLibres,
  modo,
  error,
  ocupado,
  onCancelar,
  onAgregar,
}: {
  plantilla: Plantilla;
  valores: Valores;
  setValores: (f: (v: Valores) => Valores) => void;
  libre: Record<string, string>;
  setLibre: (f: (v: Record<string, string>) => Record<string, string>) => void;
  camposLibres: CampoLibre[];
  modo: "prescripcion" | "recomendacion";
  error: string | null;
  ocupado: boolean;
  onCancelar: () => void;
  onAgregar: () => void;
}) {
  const faltan = plantilla.libre ? [] : faltantes(plantilla, valores);
  // Una lista desplegable nunca falta: siempre tiene algo escogido. Lo que se
  // vigila es lo que hay que escribir.
  const faltanLibres = plantilla.libre
    ? camposLibres.filter(
        (c) => !c.opciones && !c.opcional && !(libre[c.clave] ?? "").trim(),
      )
    : [];
  const listo = faltan.length === 0 && faltanLibres.length === 0;

  return (
    <div className="animate-in fade-in slide-in-from-top-1 space-y-5 rounded-xl border border-primary/30 bg-card p-5 shadow-sm duration-200">
      <div className="flex items-start justify-between gap-3">
        <div className="space-y-0.5">
          <h3 className="font-semibold leading-tight">{plantilla.nombre}</h3>
          <p className="text-xs text-muted-foreground">
            {plantilla.libre
              ? "No está en la lista: se escribe completo."
              : "Tocá el valor o escribilo."}
          </p>
        </div>
        <Button
          type="button"
          variant="ghost"
          size="icon"
          onClick={onCancelar}
          aria-label="Cerrar"
          className="shrink-0"
        >
          <X className="size-4" />
        </Button>
      </div>

      {plantilla.libre ? (
        <div className="grid gap-4 sm:grid-cols-2">
          {camposLibres.map((c) => (
            <div
              key={c.clave}
              className={`space-y-2 ${c.largo ? "sm:col-span-2" : ""}`}
            >
              <Label htmlFor={`libre-${c.clave}`}>{c.etiqueta}</Label>
              {c.opciones ? (
                <select
                  id={`libre-${c.clave}`}
                  value={libre[c.clave] ?? c.opciones[0]?.valor ?? ""}
                  onChange={(e) =>
                    setLibre((v) => ({ ...v, [c.clave]: e.target.value }))
                  }
                  className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-base shadow-xs transition-[color,box-shadow] outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 md:text-sm"
                >
                  {c.opciones.map((o) => (
                    <option key={o.valor} value={o.valor}>
                      {o.etiqueta}
                    </option>
                  ))}
                </select>
              ) : c.largo ? (
                <textarea
                  id={`libre-${c.clave}`}
                  rows={3}
                  value={libre[c.clave] ?? ""}
                  onChange={(e) =>
                    setLibre((v) => ({ ...v, [c.clave]: e.target.value }))
                  }
                  className="flex w-full rounded-md border border-input bg-transparent px-3 py-2 text-base shadow-xs transition-[color,box-shadow] outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 md:text-sm"
                />
              ) : (
                <Input
                  id={`libre-${c.clave}`}
                  value={libre[c.clave] ?? ""}
                  onChange={(e) =>
                    setLibre((v) => ({ ...v, [c.clave]: e.target.value }))
                  }
                />
              )}
            </div>
          ))}
        </div>
      ) : (
        <div className="space-y-5">
          {plantilla.campos.map((campo) => (
            <Control
              key={campo.clave}
              campo={campo}
              valor={valores[campo.clave] ?? ""}
              onCambiar={(nuevo) =>
                setValores((v) => ({ ...v, [campo.clave]: nuevo }))
              }
            />
          ))}
        </div>
      )}

      {!plantilla.libre && (
        <VistaPrevia plantilla={plantilla} valores={valores} modo={modo} />
      )}

      {error && (
        <Alert variant="destructive" className="animate-in fade-in">
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      <div className="flex flex-wrap items-center gap-3">
        <Button type="button" onClick={onAgregar} disabled={ocupado || !listo}>
          {ocupado ? "Agregando…" : "Agregar"}
        </Button>
        <Button type="button" variant="ghost" onClick={onCancelar}>
          Cancelar
        </Button>
        {!listo && (
          <span className="text-xs text-muted-foreground">
            Falta{" "}
            {[...faltan.map((c) => c.etiqueta), ...faltanLibres.map((c) => c.etiqueta)]
              .join(", ")
              .toLowerCase()}
            .
          </span>
        )}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Un hueco
// ---------------------------------------------------------------------------

/**
 * Los valores sugeridos van como botones y no como una lista desplegable:
 * abrir, leer y elegir son tres gestos, y tocar es uno. Cuando el valor no
 * está entre los sugeridos, "Otro" abre el campo para escribirlo.
 */
function Control({
  campo,
  valor,
  onCambiar,
}: {
  campo: CampoPlantilla;
  valor: string;
  onCambiar: (v: string) => void;
}) {
  const opciones = (campo.opciones ?? []).map(String);
  const esSugerido = opciones.includes(valor);
  const [libre, setLibre] = useState(valor !== "" && !esSugerido);
  const escribir = opciones.length === 0 || libre;

  return (
    <div className="space-y-2">
      <Label htmlFor={`campo-${campo.clave}`}>
        {campo.etiqueta}
        {campo.unidad && (
          <span className="ml-1 font-normal text-muted-foreground">
            ({campo.unidad})
          </span>
        )}
      </Label>

      {opciones.length > 0 && (
        <div className="flex flex-wrap gap-2">
          {opciones.map((o) => (
            <button
              key={o}
              type="button"
              onClick={() => {
                setLibre(false);
                onCambiar(o);
              }}
              aria-pressed={!libre && valor === o}
              className={`min-w-11 rounded-md border px-3 py-1.5 text-sm tabular-nums transition-all duration-150 ${
                !libre && valor === o
                  ? "border-primary bg-primary font-semibold text-primary-foreground"
                  : "hover:border-primary/50 hover:bg-accent"
              }`}
            >
              {o}
            </button>
          ))}

          <button
            type="button"
            onClick={() => {
              setLibre(true);
              if (esSugerido) onCambiar("");
            }}
            aria-pressed={libre}
            className={`rounded-md border px-3 py-1.5 text-sm transition-all duration-150 ${
              libre
                ? "border-primary bg-primary font-semibold text-primary-foreground"
                : "hover:border-primary/50 hover:bg-accent"
            }`}
          >
            Otro
          </button>
        </div>
      )}

      {escribir && (
        <div className="flex items-center gap-2">
          <Input
            id={`campo-${campo.clave}`}
            value={valor}
            onChange={(e) => onCambiar(e.target.value)}
            inputMode={campo.tipo === "numero" ? "decimal" : "text"}
            autoComplete="off"
            className="max-w-56"
          />
          {campo.unidad && (
            <span className="text-sm text-muted-foreground">
              {campo.unidad}
            </span>
          )}
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Lo que va a ver el paciente
// ---------------------------------------------------------------------------

function VistaPrevia({
  plantilla,
  valores,
  modo,
}: {
  plantilla: Plantilla;
  valores: Valores;
  modo: "prescripcion" | "recomendacion";
}) {
  return (
    <div className="space-y-2 rounded-lg border bg-muted/30 p-4">
      <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
        Así le llega al paciente
      </p>

      {modo === "recomendacion" ? (
        <div className="space-y-1">
          <p className="text-sm font-semibold">
            {plantilla.titulo?.trim() || plantilla.nombre}
          </p>
          <Frase
            plantilla={plantilla.plantilla}
            valores={valores}
            className="block text-sm leading-relaxed text-muted-foreground"
          />
        </div>
      ) : (
        <TarjetaComoEnLaApp plantilla={plantilla} valores={valores} />
      )}
    </div>
  );
}

/** La misma forma que `lib/widgets/tarjeta_prescripcion.dart`. */
function TarjetaComoEnLaApp({
  plantilla,
  valores,
}: {
  plantilla: Plantilla;
  valores: Valores;
}) {
  const { nombre } = armarPrescripcion(plantilla, valores);

  // Una plantilla agregada después sin declarar su corte: la frase entera
  // cae en la indicación, y la vista previa muestra eso mismo.
  if (plantilla.plantillaDosis === null) {
    return (
      <div className="space-y-1">
        <p className="text-sm font-semibold">{nombre}</p>
        <Frase
          plantilla={plantilla.plantilla}
          valores={valores}
          className="block text-xs leading-relaxed text-muted-foreground"
        />
      </div>
    );
  }

  return (
    <div className="space-y-2">
      <p className="text-sm font-semibold">{nombre}</p>

      {/* Hay plantillas sin dosis ni frecuencia aparte —el doctor escribe la
          indicación de corrido— y ahí la app no dibuja ningún chip. Un chip
          azul vacío se vería como un dato que se perdió. */}
      {(plantilla.plantillaDosis || plantilla.plantillaFrecuencia) && (
        <div className="flex flex-wrap items-center gap-2">
          {plantilla.plantillaDosis && (
            <span className="rounded-md bg-primary px-2.5 py-1 text-xs font-semibold text-primary-foreground">
              <Frase
                plantilla={plantilla.plantillaDosis}
                valores={valores}
                sobreOscuro
              />
            </span>
          )}
          {plantilla.plantillaFrecuencia && (
            <span className="rounded-md border px-2.5 py-1 text-xs font-medium text-muted-foreground">
              <Frase
                plantilla={plantilla.plantillaFrecuencia}
                valores={valores}
              />
            </span>
          )}
        </div>
      )}

      {plantilla.plantillaIndicacion && (
        <Frase
          plantilla={plantilla.plantillaIndicacion}
          valores={valores}
          className="block text-xs leading-relaxed text-muted-foreground"
        />
      )}
    </div>
  );
}
