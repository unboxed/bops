# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusTags::DecisionComponent, type: :component do
  let(:planning_application) do
    build(:planning_application, decision: decision)
  end

  before do
    render_inline(
      described_class.new(planning_application: planning_application)
    )
  end

  context "when decision is 'granted'" do
    let(:decision) { "granted" }

    it "renders 'To grant' status" do
      expect(page).to have_content("To grant")
    end
  end

  context "when decision is 'refused'" do
    let(:decision) { "refused" }

    it "renders 'To refuse' status" do
      expect(page).to have_content("To refuse")
    end
  end
end
