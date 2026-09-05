import { fireEvent, render, screen, within } from "@testing-library/react";
import axe from "axe-core";
import { describe, expect, it } from "vitest";
import { FaqList } from "@/components/faq-list";
import { BookyStage } from "@/components/booky-stage";
import { Header } from "@/components/header";
import { PricingGrid } from "@/components/pricing-grid";
import { accountLinks } from "@/config/site";
import { frequentlyAskedQuestions } from "@/content/site-content";

describe("marketing components", () => {
  it("provides a keyboard-operable FAQ accordion", () => {
    render(<FaqList items={frequentlyAskedQuestions.slice(0, 2)} />);
    const firstButton = screen.getByRole("button", {
      name: frequentlyAskedQuestions[0].question,
    });
    const secondButton = screen.getByRole("button", {
      name: frequentlyAskedQuestions[1].question,
    });

    expect(firstButton).toHaveAttribute("aria-expanded", "true");
    expect(secondButton).toHaveAttribute("aria-expanded", "false");
    fireEvent.click(secondButton);
    expect(firstButton).toHaveAttribute("aria-expanded", "false");
    expect(secondButton).toHaveAttribute("aria-expanded", "true");
  });

  it("renders the four plans without fabricated social proof", () => {
    const { container } = render(<PricingGrid />);
    expect(screen.getAllByRole("article")).toHaveLength(4);
    expect(screen.getByText("USD 6.99")).toBeInTheDocument();
    expect(container.textContent).not.toMatch(/testimonio|valoración|universidades aliadas/i);
  });

  it("has no detectable structural accessibility violations", async () => {
    const { container } = render(<FaqList items={frequentlyAskedQuestions} />);
    const result = await axe.run(container, {
      rules: { "color-contrast": { enabled: false } },
    });
    expect(result.violations).toEqual([]);
  });

  it("exposes the approved desktop and mobile navigation actions", () => {
    const { container } = render(<Header />);
    const header = within(container);

    expect(header.getAllByText("Para estudiantes").length).toBeGreaterThan(0);
    expect(header.getAllByText("Para docentes").length).toBeGreaterThan(0);
    expect(header.getAllByText("Contacto").length).toBeGreaterThan(0);
    expect(header.getAllByText("Iniciar sesión")[0]).toHaveAttribute(
      "href",
      accountLinks.login,
    );
    expect(header.getAllByText("Comenzar gratis")[0]).toHaveAttribute(
      "href",
      accountLinks.signup,
    );
  });

  it("presents Booky without exposing implementation placeholders", () => {
    render(<BookyStage />);

    expect(
      screen.getByLabelText("Presentación de Booky, compañero inteligente de aprendizaje"),
    ).toBeInTheDocument();
    expect(screen.queryByText(/asset oficial|pendiente de integración/i)).toBeNull();
  });

  it("keeps the W2 header and Booky structure accessible", async () => {
    const { container } = render(
      <>
        <Header />
        <main>
          <BookyStage />
        </main>
      </>,
    );
    const result = await axe.run(container, {
      rules: { "color-contrast": { enabled: false } },
    });

    expect(result.violations).toEqual([]);
  });
});
