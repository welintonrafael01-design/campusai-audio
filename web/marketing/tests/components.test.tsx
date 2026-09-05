import { fireEvent, render, screen } from "@testing-library/react";
import axe from "axe-core";
import { describe, expect, it } from "vitest";
import { FaqList } from "@/components/faq-list";
import { PricingGrid } from "@/components/pricing-grid";
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
});
