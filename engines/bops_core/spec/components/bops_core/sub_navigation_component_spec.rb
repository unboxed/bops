# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe(BopsCore::SubNavigationComponent, type: :component) do
  let(:navigation_items) do
    [
      {text: "Informatives", href: "/informatives"},
      {
        text: "Considerations",
        href: "/policy/areas",
        parent: true,
        children: [
          {text: "Policy areas", href: "/policy/areas", current: true},
          {text: "Policy guidance", href: "/policy/guidance"},
          {text: "Policy references", href: "/policy/references"}
        ]
      }
    ]
  end

  let(:kwargs) { {visually_hidden_title: "Policy management", navigation_items: navigation_items} }

  subject! { render_inline(described_class.new(**kwargs)) }

  it "renders the sub navigation component" do
    within "nav" do
      expect(element["aria-labelledby"]).to eq("sub-navigation-heading")
      expect(element["class"]).to eq("x-govuk-sub-navigation")

      within "> h2" do
        expect(element["id"]).to eq("sub-navigation-heading")
        expect(element["class"]).to eq("govuk-visually-hidden")
        expect(element.text).to eq("Policy management")
      end

      within "> ul" do
        expect(element["class"]).to eq("x-govuk-sub-navigation__section")

        within "> li:nth-child(1)" do
          expect(element["class"]).to eq("x-govuk-sub-navigation__section-item")

          within "> a" do
            expect(element["href"]).to eq("/informatives")
            expect(element["class"]).to eq("x-govuk-sub-navigation__link")
            expect(element["aria-current"]).to be_nil
            expect(element.text).to eq("Informatives")
          end
        end

        within "> li:nth-child(2)" do
          expect(element["class"]).to eq("x-govuk-sub-navigation__section-item x-govuk-sub-navigation__section-item--current")

          within "> a" do
            expect(element["href"]).to eq("/policy/areas")
            expect(element["class"]).to eq("x-govuk-sub-navigation__link")
            expect(element["aria-current"]).to be_nil
            expect(element.text).to eq("Considerations")
          end

          within "ul" do
            expect(element["class"]).to eq("x-govuk-sub-navigation__section x-govuk-sub-navigation__section--nested")

            within "li:nth-child(1)" do
              expect(element["class"]).to eq("x-govuk-sub-navigation__section-item")

              within "a" do
                expect(element["href"]).to eq("/policy/areas")
                expect(element["class"]).to eq("x-govuk-sub-navigation__link")
                expect(element["aria-current"]).to eq("true")
                expect(element.text).to eq("Policy areas")
              end
            end

            within "li:nth-child(2)" do
              expect(element["class"]).to eq("x-govuk-sub-navigation__section-item")

              within "a" do
                expect(element["href"]).to eq("/policy/guidance")
                expect(element["class"]).to eq("x-govuk-sub-navigation__link")
                expect(element["aria-current"]).to be_nil
                expect(element.text).to eq("Policy guidance")
              end
            end

            within "li:nth-child(3)" do
              expect(element["class"]).to eq("x-govuk-sub-navigation__section-item")

              within "a" do
                expect(element["href"]).to eq("/policy/references")
                expect(element["class"]).to eq("x-govuk-sub-navigation__link")
                expect(element["aria-current"]).to be_nil
                expect(element.text).to eq("Policy references")
              end
            end
          end
        end
      end
    end
  end

  context "when the items are grouped by theme" do
    let(:navigation_items) do
      [
        {text: "Informatives", href: "/informatives"},
        {theme: "Considerations", text: "Policy areas", href: "/policy/areas", current: true},
        {theme: "Considerations", text: "Policy guidance", href: "/policy/guidance"},
        {theme: "Considerations", text: "Policy references", href: "/policy/references"}
      ]
    end

    it "renders the sub navigation component" do
      within "nav" do
        expect(element["aria-labelledby"]).to eq("sub-navigation-heading")
        expect(element["class"]).to eq("x-govuk-sub-navigation")

        within "> h2" do
          expect(element["id"]).to eq("sub-navigation-heading")
          expect(element["class"]).to eq("govuk-visually-hidden")
          expect(element.text).to eq("Policy management")
        end

        within "> ul:nth-of-type(1)" do
          expect(element["class"]).to eq("x-govuk-sub-navigation__section")

          within "> li:nth-child(1)" do
            expect(element["class"]).to eq("x-govuk-sub-navigation__section-item")

            within "> a" do
              expect(element["href"]).to eq("/informatives")
              expect(element["class"]).to eq("x-govuk-sub-navigation__link")
              expect(element["aria-current"]).to be_nil
              expect(element.text).to eq("Informatives")
            end
          end
        end

        within "> h3:nth-of-type(1)" do
          expect(element["class"]).to eq("x-govuk-sub-navigation__theme")
          expect(element.text).to eq("Considerations")
        end

        within "> ul:nth-of-type(2)" do
          expect(element["class"]).to eq("x-govuk-sub-navigation__section")

          within "li:nth-child(1)" do
            expect(element["class"]).to eq("x-govuk-sub-navigation__section-item x-govuk-sub-navigation__section-item--current")

            within "a" do
              expect(element["href"]).to eq("/policy/areas")
              expect(element["class"]).to eq("x-govuk-sub-navigation__link")
              expect(element["aria-current"]).to eq("true")
              expect(element.text).to eq("Policy areas")
            end
          end

          within "li:nth-child(2)" do
            expect(element["class"]).to eq("x-govuk-sub-navigation__section-item")

            within "a" do
              expect(element["href"]).to eq("/policy/guidance")
              expect(element["class"]).to eq("x-govuk-sub-navigation__link")
              expect(element["aria-current"]).to be_nil
              expect(element.text).to eq("Policy guidance")
            end
          end

          within "li:nth-child(3)" do
            expect(element["class"]).to eq("x-govuk-sub-navigation__section-item")

            within "a" do
              expect(element["href"]).to eq("/policy/references")
              expect(element["class"]).to eq("x-govuk-sub-navigation__link")
              expect(element["aria-current"]).to be_nil
              expect(element.text).to eq("Policy references")
            end
          end
        end
      end
    end
  end
end
