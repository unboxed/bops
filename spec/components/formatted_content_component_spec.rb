# frozen_string_literal: true

require "rails_helper"

RSpec.describe FormattedContentComponent, type: :component do
  before { render_inline(component) }

  context "when content without a link is provided" do
    let(:component) do
      described_class.new(text: "content without link")
    end

    it "returns content with just simple formatting" do
      expect(page).to have_css "p[class='govuk-body']", text: "content without link"
    end
  end

  context "when content with a link is provided" do
    let(:component) do
      described_class.new(text: "content including link https://www.bops.co.uk/")
    end

    it "returns content including a clickable link (and opens in new tab) with simple formatting" do
      expect(page).to have_css "p[class='govuk-body']", text: "content including link https://www.bops.co.uk/"

      expect(component.auto_link_and_simple_format).to eq(
        "<p class=\"govuk-body\">content including link <a target=\"_blank\" href=\"https://www.bops.co.uk/\">https://www.bops.co.uk/</a></p>"
      )
    end
  end

  context "when link html is provided" do
    let(:component) do
      described_class.new(text: "content including html <a href='https://bops.com/validate' target='_blank'>Bops validation</a>")
    end

    it "preserves the link html content with attribute target='_blank'" do
      expect(page).to have_css "p[class='govuk-body']", text: "content including html Bops validation"

      expect(component.auto_link_and_simple_format).to eq(
        "<p class=\"govuk-body\">content including html <a href=\"https://bops.com/validate\" target=\"_blank\">Bops validation</a></p>"
      )
    end
  end

  context "when a non whitelisted attribute is added" do
    let(:component) do
      described_class.new(text: "content including http://www.bops.com <script></script>")
    end

    it "sanitizes it" do
      expect(component.auto_link_and_simple_format).to eq(
        "<p class=\"govuk-body\">content including <a target=\"_blank\" href=\"http://www.bops.com\">http://www.bops.com</a> </p>"
      )
    end
  end

  context "when specified classname/s have been added" do
    let(:component) do
      described_class.new(text: "content", classname: "govuk-body-s govuk-margin-2")
    end

    it "returns content with a specified class name" do
      expect(page).to have_css "p[class='govuk-body-s govuk-margin-2']", text: "content"
    end
  end
end
