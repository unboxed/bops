# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationSearch do
  let(:local_authority) { create(:local_authority, :default) }

  let(:assessor) do
    create(:user, :assessor, local_authority:)
  end

  let(:planning_application1) do
    travel_to("2022-01-01") do
      create(
        :planning_application,
        :not_started,
        work_status: "proposed",
        description: "Add a chimney stack.",
        local_authority:
      )
    end
  end

  let(:planning_application2) do
    travel_to("2022-02-01") do
      create(
        :planning_application,
        :in_assessment,
        description: "Something else entirely",
        local_authority:
      )
    end
  end

  let(:planning_application3) do
    travel_to("2022-03-01") do
      create(
        :planning_application,
        :in_assessment,
        description: "Skylight",
        local_authority:,
        user: assessor
      )
    end
  end

  describe "#call" do
    context "when is search with exclude_others" do
      let(:params) do
        { q: "exclude_others" }
      end

      it "returns correct planning applications" do
        allow_any_instance_of(described_class).to receive(:current_user).and_return(assessor)

        expect(described_class.new(params).call).to eq(
          [planning_application3]
        )
      end
    end

    context "when is search without params" do
      it "returns correct planning applications" do
        allow_any_instance_of(described_class).to receive(:current_user).and_return(assessor)

        expect(described_class.new.call).to eq(
          [
            planning_application3,
            planning_application2,
            planning_application1
          ]
        )
      end
    end
  end
end
