# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImmunityDetailsCreationService, type: :service do
  describe "#call" do
    let(:api_user) { create(:api_user) }

    context "when a planning application is provided" do
      let!(:planning_application) { create(:planning_application, :from_planx_immunity, api_user:) }

      context "when successful" do
        it "creates a the immunity details for the planning application" do
          expect do
            described_class.new(
              planning_application:
            ).call
          end.to change(ImmunityDetail, :count).by(1)

          immunity_detail = ImmunityDetail.last

          expect(immunity_detail).to have_attributes(
            planning_application_id: planning_application.id,
            status: "not_started",
            end_date: "2015-02-01 00:00:00.000000000 +0000".to_datetime
          )
        end
      end
    end
  end
end
