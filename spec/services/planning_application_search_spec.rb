# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationSearch do
  let(:search) { described_class.new(params) }

  let!(:local_authority) { create(:local_authority, :default) }

  let!(:assessor) do
    create(:user, :assessor, local_authority:)
  end

  let!(:application_type_ldc_proposed) { create(:application_type, :ldc_proposed, local_authority:) }
  let!(:application_type_prior_approval) { create(:application_type, :prior_approval, local_authority:) }
  let!(:application_type_householder) { create(:application_type, :householder, local_authority:) }
  let!(:application_type_pre_application) { create(:application_type, :pre_application, local_authority:) }

  let!(:ldc_not_started) do
    travel_to("2022-01-01") do
      create(
        :planning_application,
        :not_started,
        :ldc_proposed,
        description: "Add a chimney stack.",
        local_authority:,
        received_at: nil,
        application_type: application_type_ldc_proposed
      )
    end
  end

  let!(:ldc_in_assessment_1) do
    travel_to("2022-02-01") do
      create(
        :planning_application,
        :in_assessment,
        :ldc_proposed,
        description: "Something else entirely",
        local_authority:,
        received_at: nil,
        application_type: application_type_ldc_proposed
      )
    end
  end

  let!(:ldc_in_assessment_2) do
    travel_to("2022-03-01") do
      create(
        :planning_application,
        :in_assessment,
        :ldc_proposed,
        description: "Skylight",
        local_authority:,
        user: assessor,
        received_at: nil,
        application_type: application_type_ldc_proposed
      )
    end
  end

  let!(:prior_approval_not_started) do
    create(
      :planning_application,
      :not_started,
      :prior_approval,
      local_authority:,
      received_at: nil,
      application_type: application_type_prior_approval
    )
  end

  let!(:prior_approval_in_assessment) do
    create(
      :planning_application,
      :in_assessment,
      :prior_approval,
      local_authority:,
      received_at: nil,
      application_type: application_type_prior_approval
    )
  end

  let!(:householder_application_for_planning_permission_in_assessment) do
    create(
      :planning_application,
      :in_assessment,
      :planning_permission,
      local_authority:,
      received_at: nil,
      application_type: application_type_householder
    )
  end

  let!(:pre_application_in_assessment) do
    create(
      :planning_application,
      :in_assessment,
      :pre_application,
      local_authority:,
      received_at: nil,
      application_type: application_type_pre_application
    )
  end

  before do
    Current.user = assessor
  end

  describe "#call" do
    context "when is search without params" do
      let(:params) do
        ActionController::Parameters.new
      end

      it "returns correct planning applications" do
        expect(search.call).to eq([
          prior_approval_not_started,
          ldc_not_started,
          prior_approval_in_assessment,
          householder_application_for_planning_permission_in_assessment,
          ldc_in_assessment_2,
          ldc_in_assessment_1,
          pre_application_in_assessment
        ])
      end
    end

    context "when is search with exclude_others" do
      let(:params) do
        ActionController::Parameters.new(
          {view: "mine"}
        )
      end

      let!(:assessor1) do
        create(:user, :assessor, local_authority:)
      end

      let!(:planning_application4) do
        travel_to("2022-03-01") do
          create(
            :planning_application,
            :in_assessment,
            description: "Skylight",
            local_authority:,
            user: assessor1
          )
        end
      end

      it "returns any associated and unassociated planning applications" do
        expect(search.call).to contain_exactly(
          prior_approval_not_started,
          ldc_not_started,
          prior_approval_in_assessment,
          ldc_in_assessment_2,
          ldc_in_assessment_1,
          householder_application_for_planning_permission_in_assessment,
          pre_application_in_assessment
        )
      end

      it "does not return any planning application which is associated with other user" do
        expect(search.call).not_to contain_exactly(planning_application4)
      end
    end

    context "when just using search" do
      let(:params) do
        ActionController::Parameters.new(
          {
            view: "all",
            query:,
            submit: "query"
          }
        )
      end

      context "when query matches description" do
        context "when query is full description" do
          let(:query) { "Add a chimney stack." }

          it "returns correct planning applications" do
            expect(search.call).to contain_exactly(ldc_not_started)
          end
        end

        context "when query is part of description" do
          let(:query) { "chimney" }

          it "returns correct planning applications" do
            expect(search.call).to contain_exactly(ldc_not_started)
          end
        end

        context "when query is non-adjacent words from description" do
          let(:query) { "add stack" }

          it "returns correct planning applications" do
            expect(search.call).to contain_exactly(ldc_not_started)
          end
        end

        context "when query is in wrong case" do
          let(:query) { "Chimney" }

          it "returns correct planning applications" do
            expect(search.call).to contain_exactly(ldc_not_started)
          end
        end

        context "when query contains plurals instead of singulars" do
          let(:query) { "chimneys stacks" }

          it "returns correct planning applications" do
            expect(search.call).to contain_exactly(ldc_not_started)
          end
        end

        context "when query contains additional words" do
          let(:query) { "orange chimney stack" }

          it "returns correct planning applications" do
            expect(search.call).to contain_exactly(ldc_not_started)
          end
        end

        context "when more than one application matches query" do
          let!(:ldc_in_assessment_1) do
            create(:planning_application, description: "Add stack", local_authority:)
          end

          let!(:ldc_in_assessment_2) do
            create(:planning_application, description: "Add orange chimney stack", local_authority:)
          end

          let(:query) { "orange chimney stack" }

          it "returns planning applications ranked by closest match" do
            expect(search.call).to contain_exactly(
              ldc_not_started,
              ldc_in_assessment_2,
              ldc_in_assessment_1
            )
          end
        end
      end

      context "when query matches reference" do
        context "when query is full reference" do
          let(:query) { "22-00100-LDCP" }

          it "returns correct planning applications" do
            expect(search.call).to contain_exactly(ldc_not_started)
          end

          it "does not search for matching descriptions" do
            allow(search)
              .to receive(:records_matching_reference)
              .and_call_original

            allow(search).to receive(:records_matching_description)

            search.call

            expect(search).to have_received(:records_matching_reference)
            expect(search).not_to have_received(:records_matching_description)
          end
        end

        context "when query is part of reference" do
          let(:query) { "00100" }

          it "returns correct planning applications" do
            expect(search.call).to contain_exactly(ldc_not_started)
          end
        end

        context "when query is in wrong case" do
          let(:query) { "22-00100-ldcp" }

          it "returns correct planning applications" do
            expect(search.call).to contain_exactly(ldc_not_started)
          end
        end
      end

      context "when query is blank" do
        let(:query) { nil }

        it "returns all planning applications" do
          expect(search.call).to contain_exactly(
            prior_approval_not_started,
            ldc_not_started,
            prior_approval_in_assessment,
            ldc_in_assessment_2,
            ldc_in_assessment_1,
            householder_application_for_planning_permission_in_assessment,
            pre_application_in_assessment
          )
        end

        it "sets error message" do
          search.call

          expect(search.errors.full_messages).to contain_exactly(
            "Query can't be blank"
          )
        end
      end

      context "when query is has no matches" do
        let(:query) { "qwerty" }

        it "returns no planning applications" do
          expect(search.call).to be_empty
        end
      end
    end

    context "when just using filter" do
      let(:params) do
        ActionController::Parameters.new(
          {
            status: ["not_started"]
          }
        )
      end

      it "returns correct planning applications" do
        expect(search.call).to contain_exactly(
          prior_approval_not_started,
          ldc_not_started
        )
      end
    end

    context "when using search and filter" do
      let(:params) do
        ActionController::Parameters.new(
          {
            query: "Skylight",
            status: ["in_assessment"],
            submit: "search"
          }
        )
      end

      it "returns correct planning applications" do
        expect(search.call).to contain_exactly(ldc_in_assessment_2)
      end
    end

    context "when filtering by several columns" do
      context "when filtering by not started and prior approval" do
        let(:params) do
          ActionController::Parameters.new(
            {
              status: ["not_started"],
              application_type: ["prior_approval"],
              submit: "search"
            }
          )
        end

        it "returns correct planning applications" do
          expect(search.call).to contain_exactly(prior_approval_not_started)
        end
      end

      context "when filtering by in assessment and prior approval" do
        let(:params) do
          ActionController::Parameters.new(
            {
              status: ["in_assessment"],
              application_type: ["prior_approval"],
              submit: "search"
            }
          )
        end

        it "returns correct planning applications" do
          expect(search.call).to contain_exactly(prior_approval_in_assessment)
        end
      end

      context "when filtering by in assessment and pre application" do
        let(:params) do
          ActionController::Parameters.new(
            {
              status: ["in_assessment"],
              application_type: ["pre_application"],
              submit: "search"
            }
          )
        end

        it "returns correct planning applications" do
          expect(search.call).to contain_exactly(pre_application_in_assessment)
        end
      end

      context "when using search and filter with matching query" do
        let(:params) do
          ActionController::Parameters.new(
            {
              query: prior_approval_not_started.reference,
              status: ["not_started"],
              application_type: ["prior_approval"],
              submit: "search"
            }
          )
        end

        it "returns correct planning applications" do
          expect(search.call).to contain_exactly(prior_approval_not_started)
        end
      end

      context "when using search and filter without matching query" do
        let(:params) do
          ActionController::Parameters.new(
            {
              query: prior_approval_in_assessment.reference,
              status: ["not_started"],
              application_type: ["prior_approval"],
              submit: "search"
            }
          )
        end

        it "returns correct planning applications" do
          expect(search.call).to eq([])
        end
      end
    end
  end
end
