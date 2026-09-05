import { Check } from "lucide-react";
import { commercialPlans } from "@/config/plans";
import { siteConfig } from "@/config/site";

export function PricingGrid() {
  return (
    <div className="pricing-grid">
      {commercialPlans.map((plan) => {
        const href = plan.href.startsWith("/")
          ? plan.id === "institution"
            ? plan.href
            : `${siteConfig.urls.app}${plan.href}`
          : plan.href;
        return (
          <article
            className={plan.featured ? "price-card price-card-featured" : "price-card"}
            key={plan.id}
          >
            {plan.featured ? <span className="popular-badge">Más popular</span> : null}
            <p className="plan-audience">{plan.audience}</p>
            <h2>{plan.name}</h2>
            <p className="plan-price">
              {plan.price}
              {plan.cadence ? <small>{plan.cadence}</small> : null}
            </p>
            <p className="plan-description">{plan.description}</p>
            <ul>
              {plan.features.map((feature) => (
                <li key={feature}>
                  <Check aria-hidden="true" size={18} />
                  {feature}
                </li>
              ))}
            </ul>
            <a className={plan.featured ? "button" : "button button-secondary"} href={href}>
              {plan.cta}
            </a>
          </article>
        );
      })}
    </div>
  );
}
