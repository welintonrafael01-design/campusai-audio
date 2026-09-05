import Image from "next/image";

export function ProductPreview({ compact = false }: { compact?: boolean }) {
  return (
    <figure className={compact ? "product-preview product-preview-compact" : "product-preview"}>
      <span className="product-real-label">Producto real</span>
      <div className="product-browser-bar" aria-hidden="true">
        <span />
        <span />
        <span />
        <p>app.studybookai.com</p>
      </div>
      <Image
        src="/product/voice-tutor.png"
        alt="Vista real de Voice Tutor dentro de StudyBook AI, con apoyo por voz y opciones de aprendizaje."
        width={1280}
        height={778}
        sizes="(max-width: 900px) 94vw, 1080px"
        priority
      />
      {!compact ? (
        <figcaption>
          Vista de producto en entorno de QA. El contenido puede evolucionar antes
          del lanzamiento.
        </figcaption>
      ) : null}
    </figure>
  );
}
