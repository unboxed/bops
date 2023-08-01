# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConstraintQueryUpdateJob do
  let!(:planning_application) { create(:planning_application, :with_boundary_geojson) }

  before do
    stub_planx_api_response_for("POLYGON ((-0.054597 51.537331, -0.054588 51.537287, -0.054453 51.537313, -0.054597 51.537331))").to_return(
      status: 200, body: "{}"
    )
  end

  describe "#perform" do
    it "calls ConstraintQueryUpdateService" do
      expect_any_instance_of(ConstraintQueryUpdateService).to receive(:call)
        .and_call_original

      described_class.perform_now(planning_application:)
    end
  end
end
