/**
 * A dónde escribe un paciente que necesita ayuda.
 *
 * Sale en las dos páginas públicas y es lo que la App Store registra como
 * contacto de soporte, así que vive en un solo lugar: cambiarlo en una página
 * y olvidarse de la otra deja a alguien escribiéndole a una dirección muerta.
 */
export const CORREO_SOPORTE = "estebanjhc20@gmail.com";

/**
 * Por dónde se agenda desde la portada: WhatsApp (6056-6081) y las cuentas
 * de Instagram. Solo WhatsApp, a pedido de la clínica: el número no se
 * ofrece para llamadas, así que no lleva enlace `tel:` en ningún lado.
 */
export const WHATSAPP = `https://wa.me/50660566081?text=${encodeURIComponent(
  "Hola, quisiera agendar una valoración en CMR.",
)}`;

export const INSTAGRAM_CLINICA = "https://www.instagram.com/cmr.cosmeclinic/";
export const INSTAGRAM_DOCTOR = "https://www.instagram.com/drroyjimenez/";
