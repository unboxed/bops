# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe(BopsCore::SecondaryNavigationComponent, type: :component) do
  let(:items) do
    [
      {link: {text: "Policy areas", href: "/policy/areas"}, current: true},
      {link: {text: "Policy references", href: "/policy/references"}, current: false}
    ]
  end

  let(:kwargs) { {items: items} }

  subject! { render_inline(described_class.new(**kwargs)) }

  it "renders the secondary navigation component" do
    within "nav" do
      expect(element["aria-label"]).to eq("Secondary Navigation")
      expect(element["class"]).to eq("x-govuk-secondary-navigation")

      within "ul" do
        expect(element["class"]).to eq("x-govuk-secondary-navigation__list")

        within "li:nth-child(1)" do
          expect(element["class"]).to eq("x-govuk-secondary-navigation__list-item x-govuk-secondary-navigation__list-item--current")

          within "a" do
            expect(element["href"]).to eq("/policy/areas")
            expect(element["class"]).to eq("x-govuk-secondary-navigation__link")
            expect(element["aria-current"]).to eq("page")
            expect(element.text).to eq("Policy areas")
          end
        end

        within "li:nth-child(2)" do
          expect(element["class"]).to eq("x-govuk-secondary-navigation__list-item")

          within "a" do
            expect(element["href"]).to eq("/policy/references")
            expect(element["class"]).to eq("x-govuk-secondary-navigation__link")
            expect(element["aria-current"]).to be_nil
            expect(element.text).to eq("Policy references")
          end
        end
      end
    end
  end
end
