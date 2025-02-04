# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe(BopsCore::SideNavigationComponent, type: :component) do
  let(:sections) do
    [
      {
        title: "Considerations",
        index: 1,
        navigation_items: [
          {text: "Manage policy areas", href: "/policy/areas", current: true},
          {text: "Manage policy guidance", href: "/policy/guidance"},
          {text: "Manage policy references", href: "/policy/references"}
        ]
      },
      {
        title: "Informatives",
        index: 2,
        navigation_items: [
          {text: "Manage informatives", href: "/informatives"}
        ]
      }
    ]
  end

  let(:kwargs) { {title: "Policies", sections: sections} }

  subject! { render_inline(described_class.new(**kwargs)) }

  it "renders the sub navigation component" do
    within "nav" do
      expect(element["aria-labelledby"]).to eq("side-navigation-heading")
      expect(element["class"]).to eq("bops-side-navigation")

      within "> h2" do
        expect(element["id"]).to eq("side-navigation-heading")
        expect(element["class"]).to eq("bops-side-navigation__heading")
        expect(element.text).to eq("Policies")
      end

      within "> section:nth-of-type(1)" do
        expect(element["aria-labelledby"]).to eq("side-navigation-section-1-heading")
        expect(element["class"]).to eq("bops-side-navigation__section")

        within "> h3" do
          expect(element["id"]).to eq("side-navigation-section-1-heading")
          expect(element["class"]).to eq("bops-side-navigation__section-heading")
          expect(element.text).to eq("Considerations")
        end

        within "> ul" do
          expect(element["class"]).to eq("bops-side-navigation__section-list")

          within "> li:nth-child(1)" do
            expect(element["class"]).to eq("bops-side-navigation__section-item bops-side-navigation__section-item--current")

            within "> a" do
              expect(element["href"]).to eq("/policy/areas")
              expect(element["class"]).to eq("bops-side-navigation__link")
              expect(element["aria-current"]).to eq("true")
              expect(element.text).to eq("Manage policy areas")
            end
          end

          within "> li:nth-child(2)" do
            expect(element["class"]).to eq("bops-side-navigation__section-item")

            within "> a" do
              expect(element["href"]).to eq("/policy/guidance")
              expect(element["class"]).to eq("bops-side-navigation__link")
              expect(element["aria-current"]).to be_nil
              expect(element.text).to eq("Manage policy guidance")
            end
          end

          within "> li:nth-child(3)" do
            expect(element["class"]).to eq("bops-side-navigation__section-item")

            within "> a" do
              expect(element["href"]).to eq("/policy/references")
              expect(element["class"]).to eq("bops-side-navigation__link")
              expect(element["aria-current"]).to be_nil
              expect(element.text).to eq("Manage policy references")
            end
          end
        end
      end

      within "> section:nth-of-type(2)" do
        expect(element["aria-labelledby"]).to eq("side-navigation-section-2-heading")
        expect(element["class"]).to eq("bops-side-navigation__section")

        within "> h3" do
          expect(element["id"]).to eq("side-navigation-section-2-heading")
          expect(element["class"]).to eq("bops-side-navigation__section-heading")
          expect(element.text).to eq("Informatives")
        end

        within "> ul" do
          expect(element["class"]).to eq("bops-side-navigation__section-list")

          within "> li:nth-child(1)" do
            expect(element["class"]).to eq("bops-side-navigation__section-item")

            within "> a" do
              expect(element["href"]).to eq("/informatives")
              expect(element["class"]).to eq("bops-side-navigation__link")
              expect(element["aria-current"]).to be_nil
              expect(element.text).to eq("Manage informatives")
            end
          end
        end
      end
    end
  end
end
