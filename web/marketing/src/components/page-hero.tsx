import type { ReactNode } from "react";

type PageHeroProps = {
  eyebrow: string;
  title: string;
  description: string;
  actions?: ReactNode;
  visual?: ReactNode;
  tone?: "cyan" | "violet";
};

export function PageHero({
  eyebrow,
  title,
  description,
  actions,
  visual,
  tone = "cyan",
}: PageHeroProps) {
  return (
    <section className={`page-hero page-hero-${tone}`}>
      <div className={`container page-hero-inner${visual ? " page-hero-grid" : ""}`}>
        <div>
          <p className="eyebrow">{eyebrow}</p>
          <h1>{title}</h1>
          <p className="lede">{description}</p>
          {actions ? <div className="hero-actions">{actions}</div> : null}
        </div>
        {visual ? <div className="page-hero-visual">{visual}</div> : null}
      </div>
    </section>
  );
}
