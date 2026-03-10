# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe(BopsCore::EnvironmentBannerComponent, type: :component) do
  %w[development test staging].each do |environment|
    context "when the environment is '#{environment}'" do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return(environment)
      end

      it "renders the environment banner component" do
        render_inline(described_class.new)

        within ".bops-environment-banner" do
          expect(element.text).to eq("This is #{environment}. Only process test cases on this version of BOPS")
        end
      end
    end
  end

  %w[production].each do |environment|
    context "when the environment is '#{environment}'" do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return(environment)
      end

      it "doesn't render the environment banner component" do
        render_inline(described_class.new)

        expect(page).not_to have_css(".bops-environment-banner")
      end
    end
  end
end
