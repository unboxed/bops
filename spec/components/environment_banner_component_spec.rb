# frozen_string_literal: true

require "rails_helper"

RSpec.describe EnvironmentBannerComponent, type: :component do
  it "does not render if display is false" do
    render_inline(described_class.new(display: false))

    expect(page).not_to have_selector("body")
  end

  it "displays warning in the staging environment" do
    render_inline(described_class.new(display: true))

    expect(page).to have_content "This is staging. Only process test cases on this version of BoPS"
  end
end
