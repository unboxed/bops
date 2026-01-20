# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationSearch do
  let(:search) { described_class.new(params) }

  let!(:local_authority) { create(:local_authority, :default) }

  let!(:assessor) do
    create(:user, :assessor, local_authority:)
  end

  let!(:other_assessor) do
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

  let!(:closed_planning_application) do
    create(
      :planning_application,
      :closed,
      :ldc_proposed,
      local_authority:,
      user: assessor,
      received_at: nil,
      application_type: application_type_ldc_proposed
    )
  end

  let!(:audit_for_updated_application) do
    create(
      :audit,
      planning_application: ldc_in_assessment_2,
      user: other_assessor,
      activity_type: :updated,
      created_at: 1.minute.from_now
    )
  end

  let!(:another_audit_for_updated_application) do
    create(
      :audit,
      planning_application: prior_approval_in_assessment,
      user: assessor,
      activity_type: :updated,
      created_at: 2.minutes.from_now
    )
  end

  before do
    Current.user = assessor
  end

  describe "#filtered_planning_applications" do
    context "when is search without params" do
      let(:params) do
        ActionController::Parameters.new
      end

      it "returns correct planning applications" do
        expect(search.filtered_planning_applications).to eq([
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

    context "when just using search" do
      let(:params) do
        ActionController::Parameters.new(
          {
            query:,
            submit: "query"
          }
        )
      end

      context "when query matches description" do
        context "when query is full description" do
          let(:query) { "Add a chimney stack." }

          it "returns correct planning applications" do
            expect(search.filtered_planning_applications).to contain_exactly(ldc_not_started)
          end
        end

        context "when query is part of description" do
          let(:query) { "chimney" }

          it "returns correct planning applications" do
            expect(search.filtered_planning_applications).to contain_exactly(ldc_not_started)
          end
        end

        context "when query is non-adjacent words from description" do
          let(:query) { "add stack" }

          it "returns correct planning applications" do
            expect(search.filtered_planning_applications).to contain_exactly(ldc_not_started)
          end
        end

        context "when query is in wrong case" do
          let(:query) { "Chimney" }

          it "returns correct planning applications" do
            expect(search.filtered_planning_applications).to contain_exactly(ldc_not_started)
          end
        end

        context "when query contains plurals instead of singulars" do
          let(:query) { "chimneys stacks" }

          it "returns correct planning applications" do
            expect(search.filtered_planning_applications).to contain_exactly(ldc_not_started)
          end
        end

        context "when query contains additional words" do
          let(:query) { "orange chimney stack" }

          it "returns correct planning applications" do
            expect(search.filtered_planning_applications).to contain_exactly(ldc_not_started)
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
            expect(search.filtered_planning_applications).to contain_exactly(
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
            expect(search.filtered_planning_applications).to contain_exactly(ldc_not_started)
          end

          it "stops at reference search and does not search descriptions" do
            allow(BopsCore::Filters::TextSearch::DescriptionSearch).to receive(:apply).and_call_original

            search.filtered_planning_applications

            expect(BopsCore::Filters::TextSearch::DescriptionSearch).not_to have_received(:apply)
          end
        end

        context "when query is part of reference" do
          let(:query) { "00100" }

          it "returns correct planning applications" do
            expect(search.filtered_planning_applications).to contain_exactly(ldc_not_started)
          end
        end

        context "when query is in wrong case" do
          let(:query) { "22-00100-ldcp" }

          it "returns correct planning applications" do
            expect(search.filtered_planning_applications).to contain_exactly(ldc_not_started)
          end
        end
      end

      context "when query is blank" do
        let(:query) { nil }

        it "returns all planning applications" do
          expect(search.filtered_planning_applications).to contain_exactly(
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
          search.filtered_planning_applications

          expect(search.errors.full_messages).to contain_exactly(
            "Query can't be blank"
          )
        end
      end

      context "when query is has no matches" do
        let(:query) { "qwerty" }

        it "returns no planning applications" do
          expect(search.filtered_planning_applications).to be_empty
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
        expect(search.filtered_planning_applications).to contain_exactly(
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
        expect(search.filtered_planning_applications).to contain_exactly(ldc_in_assessment_2)
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
          expect(search.filtered_planning_applications).to contain_exactly(prior_approval_not_started)
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
          expect(search.filtered_planning_applications).to contain_exactly(prior_approval_in_assessment)
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
          expect(search.filtered_planning_applications).to contain_exactly(pre_application_in_assessment)
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
          expect(search.filtered_planning_applications).to contain_exactly(prior_approval_not_started)
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
          expect(search.filtered_planning_applications).to eq([])
        end
      end
    end
  end

  describe "#closed_planning_applications" do
    context "when searching by reference" do
      let(:params) do
        ActionController::Parameters.new(
          {
            query: closed_planning_application.reference,
            submit: "search"
          }
        )
      end

      it "returns closed planning applications that match the query" do
        expect(search.closed_planning_applications).to contain_exactly(closed_planning_application)
      end
    end
  end

  describe "#updated_planning_application_audits" do
    context "when no search params are provided" do
      let(:params) { ActionController::Parameters.new }

      it "includes audits that were not made by the assigned officer" do
        expect(search.updated_planning_application_audits).to include(
          audit_for_updated_application,
          another_audit_for_updated_application
        )
      end
    end

    context "when searching by reference" do
      let(:params) do
        ActionController::Parameters.new(
          {
            query: ldc_in_assessment_2.reference,
            submit: "search"
          }
        )
      end

      it "returns audits for planning applications that match the query" do
        expect(search.updated_planning_application_audits).to contain_exactly(audit_for_updated_application)
      end
    end

    context "when filtering by status" do
      let(:params) do
        ActionController::Parameters.new(
          status: ["in_assessment"]
        )
      end

      it "returns audits only for applications with matching status" do
        expect(search.updated_planning_application_audits).to include(
          audit_for_updated_application,
          another_audit_for_updated_application
        )
      end

      it "excludes audits for applications with non-matching status" do
        result = search.updated_planning_application_audits

        result.each do |audit|
          expect(audit.planning_application.status).to eq("in_assessment")
        end
      end
    end

    context "when filtering by application_type" do
      let(:params) do
        ActionController::Parameters.new(
          application_type: [application_type_ldc_proposed.name]
        )
      end

      it "returns audits for applications with matching type" do
        expect(search.updated_planning_application_audits).to include(audit_for_updated_application)
      end

      it "excludes audits for applications with non-matching type" do
        expect(search.updated_planning_application_audits).not_to include(another_audit_for_updated_application)
      end

      context "with prior_approval type" do
        let(:params) do
          ActionController::Parameters.new(
            application_type: [application_type_prior_approval.name]
          )
        end

        it "returns audits for prior approval applications" do
          expect(search.updated_planning_application_audits).to include(another_audit_for_updated_application)
        end

        it "excludes audits for non-prior_approval applications" do
          expect(search.updated_planning_application_audits).not_to include(audit_for_updated_application)
        end
      end
    end

    context "when filtering by both status and application_type" do
      let(:params) do
        ActionController::Parameters.new(
          status: ["in_assessment"],
          application_type: [application_type_ldc_proposed.name]
        )
      end

      it "includes audits matching both filters" do
        expect(search.updated_planning_application_audits).to include(audit_for_updated_application)
      end

      it "excludes audits not matching both filters" do
        # another_audit_for_updated_application is for prior_approval, not ldc_proposed
        expect(search.updated_planning_application_audits).not_to include(another_audit_for_updated_application)
      end

      context "when filters match no audited applications" do
        let(:params) do
          ActionController::Parameters.new(
            status: ["withdrawn"],
            application_type: [application_type_prior_approval.name]
          )
        end

        it "returns empty when no applications match both filters" do
          expect(search.updated_planning_application_audits).to be_empty
        end
      end
    end

    context "when searching by description" do
      let(:params) do
        ActionController::Parameters.new(
          query: "Skylight",
          submit: "search"
        )
      end

      it "returns audits for applications matching description" do
        expect(search.updated_planning_application_audits).to contain_exactly(audit_for_updated_application)
      end
    end

    context "when searching by postcode" do
      let!(:app_with_postcode) do
        create(
          :planning_application,
          :in_assessment,
          local_authority:,
          postcode: "EC1A 1BB",
          description: "Different"
        )
      end

      let!(:audit_for_postcode_app) do
        create(
          :audit,
          planning_application: app_with_postcode,
          user: other_assessor,
          activity_type: :updated,
          created_at: 3.minutes.from_now
        )
      end

      let(:params) do
        ActionController::Parameters.new(
          query: "EC1A 1BB",
          submit: "search"
        )
      end

      it "returns audits for applications matching postcode" do
        expect(search.updated_planning_application_audits).to contain_exactly(audit_for_postcode_app)
      end
    end

    context "when searching by address" do
      let!(:app_with_address) do
        create(
          :planning_application,
          :in_assessment,
          local_authority:,
          address_1: "789 Baker Street",
          description: "Unrelated"
        )
      end

      let!(:audit_for_address_app) do
        create(
          :audit,
          planning_application: app_with_address,
          user: other_assessor,
          activity_type: :updated,
          created_at: 4.minutes.from_now
        )
      end

      let(:params) do
        ActionController::Parameters.new(
          query: "Baker Street",
          submit: "search"
        )
      end

      it "returns audits for applications matching address" do
        expect(search.updated_planning_application_audits).to contain_exactly(audit_for_address_app)
      end
    end

    context "when combining filters and text search" do
      let(:params) do
        ActionController::Parameters.new(
          status: ["in_assessment"],
          application_type: [application_type_ldc_proposed.name],
          query: "Skylight",
          submit: "search"
        )
      end

      it "applies filters and text search together" do
        expect(search.updated_planning_application_audits).to contain_exactly(audit_for_updated_application)
      end

      context "when text search has no matches within filtered results" do
        let(:params) do
          ActionController::Parameters.new(
            status: ["in_assessment"],
            application_type: [application_type_prior_approval.name],
            query: "Skylight",
            submit: "search"
          )
        end

        it "returns empty when query doesn't match filtered applications" do
          expect(search.updated_planning_application_audits).to be_empty
        end
      end
    end

    context "when query has no matches at all" do
      let(:params) do
        ActionController::Parameters.new(
          query: "zznonexistent99887766",
          submit: "search"
        )
      end

      it "returns empty result" do
        expect(search.updated_planning_application_audits).to be_empty
      end
    end

    context "when query is invalid (blank with submit)" do
      let(:params) do
        ActionController::Parameters.new(
          query: "",
          submit: "search"
        )
      end

      it "returns all audits (validation fails, text search skipped)" do
        # When query is blank but submit is present, validation fails
        # and text search is not applied, so all audits are returned
        expect(search.updated_planning_application_audits).to include(
          audit_for_updated_application,
          another_audit_for_updated_application
        )
      end
    end

    context "when no audits exist for any application" do
      before do
        Audit.delete_all
      end

      let(:params) { ActionController::Parameters.new }

      it "returns empty result" do
        expect(search.updated_planning_application_audits).to be_empty
      end
    end
  end

  describe "#reviewer_planning_applications" do
    let(:params) { ActionController::Parameters.new }

    let!(:to_be_reviewed_app) do
      create(
        :planning_application,
        :to_be_reviewed,
        local_authority:,
        user: assessor
      )
    end

    it "returns to_be_reviewed applications for current user" do
      expect(search.reviewer_planning_applications).to include(to_be_reviewed_app)
    end

    it "excludes applications not assigned to current user" do
      other_user_app = create(
        :planning_application,
        :to_be_reviewed,
        local_authority:,
        user: other_assessor
      )

      expect(search.reviewer_planning_applications).not_to include(other_user_app)
    end
  end

  describe "#unstarted_prior_approvals" do
    let(:params) { ActionController::Parameters.new }

    it "returns not_started prior approvals for current user" do
      prior_approval_not_started.case_record.update!(user: assessor)

      expect(search.unstarted_prior_approvals).to include(prior_approval_not_started)
    end

    it "excludes prior approvals that are in_assessment" do
      expect(search.unstarted_prior_approvals).not_to include(prior_approval_in_assessment)
    end

    it "excludes non-prior_approval application types" do
      expect(search.unstarted_prior_approvals).not_to include(ldc_not_started)
    end
  end

  describe "#pre_applications" do
    let(:params) { ActionController::Parameters.new }

    it "returns pre_application type applications" do
      expect(search.pre_applications).to include(pre_application_in_assessment)
    end

    it "excludes other application types" do
      expect(search.pre_applications).not_to include(ldc_not_started)
      expect(search.pre_applications).not_to include(prior_approval_not_started)
    end
  end

  describe "status filtering" do
    context "with multiple statuses" do
      let(:params) do
        ActionController::Parameters.new(
          status: %w[not_started in_assessment]
        )
      end

      it "returns applications matching any of the statuses" do
        result = search.filtered_planning_applications
        expect(result).to include(ldc_not_started, prior_approval_not_started)
        expect(result).to include(ldc_in_assessment_1, ldc_in_assessment_2)
      end
    end

    context "with status array containing empty strings" do
      let(:params) do
        ActionController::Parameters.new(
          status: ["not_started", "", ""]
        )
      end

      it "ignores empty strings and filters by remaining statuses" do
        result = search.filtered_planning_applications
        expect(result).to contain_exactly(ldc_not_started, prior_approval_not_started)
      end
    end

    context "with invalid status" do
      let(:params) do
        ActionController::Parameters.new(
          status: ["nonexistent_status"]
        )
      end

      it "returns no applications" do
        expect(search.filtered_planning_applications).to be_empty
      end
    end
  end

  describe "application type filtering" do
    context "with multiple application types" do
      let(:params) do
        ActionController::Parameters.new(
          application_type: [
            application_type_ldc_proposed.name,
            application_type_prior_approval.name
          ]
        )
      end

      it "returns applications matching any type" do
        result = search.filtered_planning_applications
        expect(result).to include(ldc_not_started, ldc_in_assessment_1, ldc_in_assessment_2)
        expect(result).to include(prior_approval_not_started, prior_approval_in_assessment)
        expect(result).not_to include(householder_application_for_planning_permission_in_assessment)
      end
    end

    context "with invalid application type" do
      let(:params) do
        ActionController::Parameters.new(
          application_type: ["nonexistent_type"]
        )
      end

      it "ignores the filter and returns all applications matching default statuses" do
        # When application_type doesn't match any types, the filter is not applied
        # and results fall back to just the status filter
        result = search.filtered_planning_applications
        expect(result).not_to be_empty
      end
    end
  end

  describe "postcode search" do
    let!(:app_with_postcode) do
      create(
        :planning_application,
        :in_assessment,
        local_authority:,
        postcode: "SW1A 1AA",
        description: "Unrelated description"
      )
    end

    context "with postcode format query" do
      let(:params) do
        ActionController::Parameters.new(
          query: "SW1A 1AA",
          submit: "search"
        )
      end

      it "matches the postcode" do
        expect(search.filtered_planning_applications).to include(app_with_postcode)
      end
    end

    context "with postcode without spaces" do
      let(:params) do
        ActionController::Parameters.new(
          query: "SW1A1AA",
          submit: "search"
        )
      end

      it "matches postcode regardless of spacing" do
        expect(search.filtered_planning_applications).to include(app_with_postcode)
      end
    end

    context "with lowercase postcode" do
      let(:params) do
        ActionController::Parameters.new(
          query: "sw1a 1aa",
          submit: "search"
        )
      end

      it "matches case-insensitively" do
        expect(search.filtered_planning_applications).to include(app_with_postcode)
      end
    end
  end

  describe "address search" do
    let!(:app_with_address) do
      create(
        :planning_application,
        :in_assessment,
        local_authority:,
        address_1: "123 High Street",
        town: "London",
        description: "Completely different"
      )
    end

    context "with address words" do
      let(:params) do
        ActionController::Parameters.new(
          query: "High Street",
          submit: "search"
        )
      end

      it "matches address using full-text search" do
        expect(search.filtered_planning_applications).to include(app_with_address)
      end
    end

    context "with multiple address words" do
      let(:params) do
        ActionController::Parameters.new(
          query: "123 High",
          submit: "search"
        )
      end

      it "requires all words to match" do
        expect(search.filtered_planning_applications).to include(app_with_address)
      end
    end
  end

  describe "sorting" do
    let!(:app_expiring_soon) do
      create(
        :planning_application,
        :in_assessment,
        local_authority:,
        expiry_date: 5.days.from_now
      )
    end

    let!(:app_expiring_later) do
      create(
        :planning_application,
        :in_assessment,
        local_authority:,
        expiry_date: 30.days.from_now
      )
    end

    context "with sort_key expiry_date ascending" do
      let(:params) do
        ActionController::Parameters.new(
          sort_key: "expiry_date",
          direction: "asc"
        )
      end

      it "places applications expiring sooner before those expiring later" do
        result = search.filtered_planning_applications
        expect(result.index(app_expiring_soon)).to be < result.index(app_expiring_later)
      end
    end

    context "with sort_key expiry_date descending" do
      let(:params) do
        ActionController::Parameters.new(
          sort_key: "expiry_date",
          direction: "desc"
        )
      end

      it "places applications expiring later before those expiring sooner" do
        result = search.filtered_planning_applications
        expect(result.index(app_expiring_later)).to be < result.index(app_expiring_soon)
      end
    end

    context "with unknown sort_key" do
      let(:params) do
        ActionController::Parameters.new(
          sort_key: "unknown_field",
          direction: "asc"
        )
      end

      it "returns results without raising error" do
        expect { search.filtered_planning_applications }.not_to raise_error
      end
    end
  end

  describe "combined filters" do
    context "with status, application_type, and query" do
      let(:params) do
        ActionController::Parameters.new(
          status: ["in_assessment"],
          application_type: [application_type_ldc_proposed.name],
          query: "Skylight",
          submit: "search"
        )
      end

      it "applies all filters together" do
        result = search.filtered_planning_applications
        expect(result).to contain_exactly(ldc_in_assessment_2)
      end
    end

    context "with status, application_type, and sorting" do
      let!(:app_expiring_soon) do
        create(
          :planning_application,
          :in_assessment,
          :ldc_proposed,
          local_authority:,
          application_type: application_type_ldc_proposed,
          expiry_date: 5.days.from_now
        )
      end

      let!(:app_expiring_later) do
        create(
          :planning_application,
          :in_assessment,
          :ldc_proposed,
          local_authority:,
          application_type: application_type_ldc_proposed,
          expiry_date: 30.days.from_now
        )
      end

      let(:params) do
        ActionController::Parameters.new(
          status: ["in_assessment"],
          application_type: [application_type_ldc_proposed.name],
          sort_key: "expiry_date",
          direction: "asc"
        )
      end

      it "applies filters and sorting together" do
        result = search.filtered_planning_applications
        expect(result.index(app_expiring_soon)).to be < result.index(app_expiring_later)
      end
    end
  end

  describe "default values" do
    let(:params) { ActionController::Parameters.new }

    it "sets default statuses" do
      expect(search.status).to eq(described_class::SELECTED_STATUSES)
    end

    it "sets default application types" do
      expect(search.application_type).to eq(described_class::APPLICATION_TYPES)
    end
  end

  describe "validation" do
    context "when submit is present but query is blank" do
      let(:params) do
        ActionController::Parameters.new(
          query: "",
          submit: "search"
        )
      end

      it "is invalid" do
        search.filtered_planning_applications
        expect(search).not_to be_valid
        expect(search.errors[:query]).to include("can't be blank")
      end
    end

    context "when submit is not present" do
      let(:params) do
        ActionController::Parameters.new(
          query: ""
        )
      end

      it "is valid without query" do
        expect(search).to be_valid
      end
    end
  end
end
