# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe(GovukComponent::PrimaryNavigationComponent, type: :component) do
  let(:items) do
    [
      {link: {text: "Dashboard", href: "/dashboard"}, current: true},
      {link: {text: "Users", href: "/users"}, current: false},
      {link: {text: "Profile", href: "/profile"}, current: false}
    ]
  end

  let(:kwargs) { {items: items} }

  subject! { render_inline(described_class.new(**kwargs)) }

  it "renders the primary navigation component" do
    within "nav" do
      expect(element["aria-labelledby"]).to eq("primary-navigation-heading")
      expect(element["class"]).to eq("x-govuk-primary-navigation")

      within "div" do
        expect(element["class"]).to eq("govuk-width-container")

        within "h2" do
          expect(element["id"]).to eq("primary-navigation-heading")
          expect(element["class"]).to eq("govuk-visually-hidden")
          expect(element.text).to eq("Navigation")
        end

        within "ul" do
          expect(element["class"]).to eq("x-govuk-primary-navigation__list")

          within "li:nth-child(1)" do
            expect(element["class"]).to eq("x-govuk-primary-navigation__item x-govuk-primary-navigation__item--current")

            within "a" do
              expect(element["href"]).to eq("/dashboard")
              expect(element["class"]).to eq("x-govuk-primary-navigation__link")
              expect(element["aria-current"]).to eq("page")
              expect(element.text).to eq("Dashboard")
            end
          end

          within "li:nth-child(2)" do
            expect(element["class"]).to eq("x-govuk-primary-navigation__item")

            within "a" do
              expect(element["href"]).to eq("/users")
              expect(element["class"]).to eq("x-govuk-primary-navigation__link")
              expect(element["aria-current"]).to be_nil
              expect(element.text).to eq("Users")
            end
          end

          within "li:nth-child(3)" do
            expect(element["class"]).to eq("x-govuk-primary-navigation__item")

            within "a" do
              expect(element["href"]).to eq("/profile")
              expect(element["class"]).to eq("x-govuk-primary-navigation__link")
              expect(element["aria-current"]).to be_nil
              expect(element.text).to eq("Profile")
            end
          end
        end
      end
    end
  end
end
