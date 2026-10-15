"use client";

import { Play } from "lucide-react";
import { useState } from "react";

export type Reel = { clave: string; titulo: string; tema: string };

/**
 * Los videos del doctor, en formato vertical como se grabaron.
 *
 * Hasta que alguien toca uno, solo se muestra el póster: seis videos con
 * `preload` harían bajar varios megas a quien quizá no vea ninguno. Y solo
 * suena uno a la vez: al tocar otro, el anterior vuelve a ser póster.
 */
export function Reels({ reels }: { reels: Reel[] }) {
  const [activo, setActivo] = useState<string | null>(null);

  return (
    <ul className="-mx-4 flex snap-x snap-mandatory gap-4 overflow-x-auto px-4 pb-4 sm:mx-0 sm:grid sm:grid-cols-2 sm:overflow-visible sm:px-0 lg:grid-cols-3 xl:grid-cols-6">
      {reels.map((r) => (
        <li key={r.clave} className="w-[68%] shrink-0 snap-center sm:w-auto">
          <figure className="space-y-3">
            <div className="relative aspect-[9/16] overflow-hidden rounded-2xl bg-[#10102e] shadow-lg shadow-[#090972]/10 ring-1 ring-black/5">
              {activo === r.clave ? (
                <video
                  src={`/inicio/${r.clave}.mp4`}
                  poster={`/inicio/${r.clave}.jpg`}
                  controls
                  autoPlay
                  playsInline
                  className="size-full object-cover"
                />
              ) : (
                <button
                  type="button"
                  onClick={() => setActivo(r.clave)}
                  className="group absolute inset-0 size-full cursor-pointer outline-none focus-visible:ring-4 focus-visible:ring-[#86dbfb] focus-visible:ring-inset"
                  aria-label={`Ver video: ${r.titulo}`}
                >
                  {/* eslint-disable-next-line @next/next/no-img-element -- póster liviano y ya del tamaño justo */}
                  <img
                    src={`/inicio/${r.clave}.jpg`}
                    alt=""
                    loading="lazy"
                    className="size-full object-cover transition-transform duration-500 group-hover:scale-105"
                  />
                  <span className="absolute inset-0 bg-gradient-to-t from-[#090972]/85 via-[#090972]/10 to-transparent" />
                  <span className="absolute left-1/2 top-1/2 flex size-14 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full bg-white/90 text-[#090972] shadow-xl backdrop-blur transition-transform duration-300 group-hover:scale-110">
                    <Play className="ml-0.5 size-6 fill-current" />
                  </span>
                  <span className="absolute inset-x-3 bottom-3 text-left text-[0.7rem] font-semibold uppercase tracking-[0.18em] text-[#86dbfb]">
                    {r.tema}
                  </span>
                </button>
              )}
            </div>
            <figcaption className="px-1 text-sm font-medium leading-snug text-[#10102e]">
              {r.titulo}
            </figcaption>
          </figure>
        </li>
      ))}
    </ul>
  );
}
