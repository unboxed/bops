# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe(BopsCore::TableOfContentsComponent, type: :component) do
  context "when links include visibility conditions" do
    let(:sections) do
      [
        {
          title: "Section",
          links: [
            {text: "Visible link", href: "#visible"},
            {text: "Hidden link", href: "#hidden", visible: false},
            {text: "Another visible link", href: "#another-visible", visible: true}
          ]
        }
      ]
    end

    subject!(:component) { render_inline(described_class.new(sections: sections)) }

    it "renders only the links with truthy conditions" do
      within ".bops-table-of-contents" do
        within "ol" do
          expect(element).to have_selector("li", count: 2)
          expect(element).to have_link("Visible link", href: "#visible")
          expect(element).to have_link("Another visible link", href: "#another-visible")
          expect(element).not_to have_link("Hidden link", href: "#hidden")
        end
      end
    end
  end
end
