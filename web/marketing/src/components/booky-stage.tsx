import Image from "next/image";

type BookyStageProps = {
  compact?: boolean;
  decorative?: boolean;
  message?: string;
  priority?: boolean;
};

export function BookyStage({
  compact = false,
  decorative = false,
  message = "Hola, soy Booky. Tu compañero inteligente de aprendizaje.",
  priority = false,
}: BookyStageProps) {
  return (
    <figure
      className={compact ? "booky-stage booky-stage-compact" : "booky-stage"}
      aria-label={
        decorative
          ? undefined
          : "Presentación de Booky, compañero inteligente de aprendizaje"
      }
      aria-hidden={decorative || undefined}
    >
      <div className="booky-atmosphere" aria-hidden="true">
        <span className="booky-orbit" />
        <span className="booky-star booky-star-one" />
        <span className="booky-star booky-star-two" />
        <span className="booky-star booky-star-three" />
      </div>
      <div className="booky-art">
        <Image
          src="/brand/booky/booky-official-front.webp"
          alt={
            decorative
              ? ""
              : "Booky, el compañero inteligente de aprendizaje de StudyBook AI"
          }
          width={1254}
          height={1254}
          priority={priority}
          loading={priority ? "eager" : "lazy"}
          sizes={
            compact
              ? "(max-width: 480px) 82vw, (max-width: 980px) 62vw, 420px"
              : "(max-width: 480px) 88vw, (max-width: 980px) 68vw, 540px"
          }
        />
      </div>
      <figcaption className="booky-bubble">{message}</figcaption>
    </figure>
  );
}
