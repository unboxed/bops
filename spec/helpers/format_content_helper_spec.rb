# frozen_string_literal: true

require "rails_helper"

RSpec.describe FormatContentHelper do
  describe "#auto_link_and_simple_format_content" do
    it "returns content without a link with just simple formatting" do
      content = "content without link"

      expect(auto_link_and_simple_format_content(content: content)).to eq("<p class=\"govuk-body\">content without link</p>")
    end

    it "returns content including a link with simple and auto link (opens in new tab) formatting" do
      content = "content including link https://www.bops.co.uk/"

      expect(auto_link_and_simple_format_content(content: content)).to eq(
        "<p class=\"govuk-body\">content including link <a target=\"_blank\" href=\"https://www.bops.co.uk/\">https://www.bops.co.uk/</a></p>"
      )
    end

    it "preserves link html content with attribute target='_blank'" do
      content = "content including html <a href='https://bops.com/validate' target='_blank'>Bops validation</a>"

      expect(auto_link_and_simple_format_content(content: content)).to eq(
        "<p class=\"govuk-body\">content including html <a href=\"https://bops.com/validate\" target=\"_blank\">Bops validation</a></p>"
      )
    end

    it "sanitizes non whitelisted content" do
      content = "content including http://www.bops.com <script></script>"

      expect(auto_link_and_simple_format_content(content: content)).to eq(
        "<p class=\"govuk-body\">content including <a target=\"_blank\" href=\"http://www.bops.com\">http://www.bops.com</a> </p>"
      )
    end

    it "returns content with a specified class name" do
      content = "content"
      classname = "govuk-body-s"

      expect(auto_link_and_simple_format_content(content: content, classname: classname)).to eq("<p class=\"govuk-body-s\">content</p>")
    end
  end
end
