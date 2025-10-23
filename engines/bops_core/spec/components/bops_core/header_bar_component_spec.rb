# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::HeaderBarComponent, type: :component do
  let(:left_items) do
    [
      {text: "REF/123", bold: true, class: "u-ref"},
      {text: "10 Downing St, London", class: "u-address"}
    ]
  end

  let(:right_items) do
    [
      {label: "Application information", href: "/applications/1/edit"},
      {label: "Documents", href: "/applications/1/documents", class: "u-docs"},
      {label: "Constraints", type: "button", data: {controller: "constraints"}}
    ]
  end

  def render_component(sticky: true, left: left_items, right: right_items, toggle: nil)
    render_inline(described_class.new(left: left, right: right, sticky: sticky, toggle: toggle))
  end

  it "renders the container with sticky modifier by default" do
    render_component
    expect(page).to have_css(".bops-header-bar.bops-header-bar--sticky")
    expect(page).to have_css(".bops-header-bar__inner")
  end

  it "renders static modifier when sticky is false" do
    render_component(sticky: false)
    expect(page).to have_css(".bops-header-bar.bops-header-bar--static")
    expect(page).not_to have_css(".bops-header-bar--sticky")
  end

  it "renders left items with GOV.UK bold class when bold is true and merges extra classes" do
    render_component

    expect(page).to have_css('.bops-header-bar__left .bops-header-bar__text.u-ref[class~="govuk-!-font-weight-bold"]', text: "REF/123")

    el = page.find(".bops-header-bar__left .bops-header-bar__text.u-ref", text: "REF/123")
    expect(el[:class].to_s.split).to include("govuk-!-font-weight-bold")
  end

  it "renders dividers between left items (count = n-1)" do
    render_component
    expect(page).to have_css(".bops-header-bar__divider", count: left_items.size - 1)
  end

  it "renders right items as links when href present (using govuk_link_to), and as a button otherwise" do
    render_component

    expect(page).to have_link("Application information", href: "/applications/1/edit")
    expect(page).to have_link("Documents", href: "/applications/1/documents")

    expect(page).to have_button("Constraints")
    expect(page).to have_css("button.button-as-link.govuk-link", text: "Constraints")
  end

  it "adds rel noopener to external links opened in a new tab" do
    render_component

    rels = page.all('a[target="_blank"]').map { |a| a[:rel].to_s }
    expect(rels).to all(include("noopener"))
  end

  it "passes through custom classes on right-side links" do
    render_component
    docs_link = page.find("a", text: "Documents")
    expect(docs_link[:class].to_s).to include("u-docs")
  end

  context "with minimal inputs" do
    it "handles empty right items" do
      render_component(right: [])
      expect(page).to have_css(".bops-header-bar__right")
      expect(page).not_to have_link("Documents")
    end

    it "puts single left item into an array" do
      render_component(left: {text: "Only item"}, right: [])
      expect(page).to have_css(".bops-header-bar__left .bops-header-bar__text", text: "Only item")
      expect(page).not_to have_css(".bops-header-bar__divider")
    end
  end

  context "when a toggle is provided" do
    let(:toggle_options) do
      {
        condensed_text: "Show proposal description",
        expanded_text: "Hide proposal description",
        content: "Proposal details go here"
      }
    end

    it "renders a toggle button and hidden panel" do
      render_component(toggle: toggle_options)

      container = page.find(".bops-header-bar")
      expect(container["data-controller"]).to eq("toggle")
      expect(container["data-toggle-condensed-text-value"]).to eq("Show proposal description")
      expect(container["data-toggle-expanded-text-value"]).to eq("Hide proposal description")
      expect(container["data-toggle-class-name-value"]).to eq("govuk-!-display-none")

      toggle_button = page.find("button.bops-header-bar__toggle-button", visible: :all)
      expect(toggle_button.text).to eq("Show proposal description")
      expect(toggle_button["data-action"]).to eq("toggle#click")
      expect(toggle_button["aria-expanded"]).to eq("false")

      panel = page.find(".bops-header-bar__toggle-panel", visible: :all)
      expect(panel[:class]).to include("govuk-!-display-none")
      expect(panel.text).to include("Proposal details go here")
    end
  end
end
