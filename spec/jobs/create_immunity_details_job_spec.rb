# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateImmunityDetailsJob do
  let!(:planning_application) { create(:planning_application, :from_planx_immunity) }

  describe "#perform" do
    it "calls CreateImmunityDetailsService" do
      expect_any_instance_of(ImmunityDetailsCreationService).to receive(:call)
        .and_call_original

      described_class.perform_now(planning_application:)
    end
  end
end
