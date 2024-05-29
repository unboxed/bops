# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShowMoreTextComponent, type: :component do
  let(:component) { described_class.new(text: "one two three four five", length:) }

  before { render_inline(component).to_html }

  context "when the text is shorter than the required length" do
    let(:length) { 300 }

    it "returns the full content" do
      expect(page).to have_content "one two three four five"
    end

    it "does not have any hidden content" do
      expect(page).not_to have_css ".hidden-content"
    end

    it "does not have a 'view more' button" do
      expect(page).not_to have_content "View more"
    end
  end

  context "when the text is longer than the required length" do
    let(:length) { 16 }

    it "returns the truncated content" do
      expect(page).to have_css ".truncated-content", text: "one two three..."
    end

    it "returns the full content, hidden" do
      expect(page).to have_css ".hidden-content", text: "one two three four five"
    end

    it "has a 'view more' button" do
      expect(page).to have_content "View more"
    end
  end
end
