# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConsistencyChecklist do
  describe "#valid?" do
    let(:planning_application) { build(:planning_application) }

    it "is true for factory" do
      expect(build(:consistency_checklist).valid?).to be(true)
    end

    context "when status is 'complete'" do
      let(:consistency_checklist) do
        build(
          :consistency_checklist,
          :complete,
          :all_checks_assessed,
          planning_application: planning_application
        )
      end

      context "when there are open description change requests" do
        before do
          create(
            :description_change_validation_request,
            :open,
            planning_application: planning_application
          )
        end

        it "returns false" do
          expect(consistency_checklist.valid?).to be(false)
        end

        it "sets error message" do
          consistency_checklist.valid?

          expect(
            consistency_checklist.errors.messages[:description_matches_documents]
          ).to contain_exactly(
            "Description change requests must be closed or cancelled"
          )
        end
      end

      context "when there are open additional document requests" do
        before do
          create(
            :additional_document_validation_request,
            :open,
            planning_application: planning_application
          )
        end

        it "returns false" do
          expect(consistency_checklist.valid?).to be(false)
        end

        it "sets error message" do
          consistency_checklist.valid?

          expect(
            consistency_checklist.errors.messages[:documents_consistent]
          ).to contain_exactly(
            "Additional document requests must be closed or cancelled"
          )
        end
      end

      context "when all requests are closed" do
        before do
          create(
            :additional_document_validation_request,
            :closed,
            planning_application: planning_application
          )

          create(
            :description_change_validation_request,
            :closed,
            planning_application: planning_application
          )
        end

        it "returns true" do
          expect(consistency_checklist.valid?).to be(true)
        end
      end

      context "when description_matches_documents is not determined" do
        let(:consistency_checklist) do
          build(
            :consistency_checklist,
            :complete,
            description_matches_documents: :to_be_determined,
            documents_consistent: :yes,
            proposal_details_match_documents: :yes
          )
        end

        it "returns false" do
          expect(consistency_checklist.valid?).to be(false)
        end

        it "sets error message" do
          consistency_checklist.valid?

          expect(
            consistency_checklist.errors.messages[:description_matches_documents]
          ).to contain_exactly(
            "Determine whether the description matches the development or use in the plans"
          )
        end
      end

      context "when proposal_details_match_documents is not determined" do
        let(:consistency_checklist) do
          build(
            :consistency_checklist,
            :complete,
            description_matches_documents: :yes,
            documents_consistent: :yes,
            proposal_details_match_documents: :to_be_determined
          )
        end

        it "returns false" do
          expect(consistency_checklist.valid?).to be(false)
        end

        it "sets error message" do
          consistency_checklist.valid?

          expect(
            consistency_checklist.errors.messages[:proposal_details_match_documents]
          ).to contain_exactly(
            "Determine whether the proposal details are consistent with the plans"
          )
        end
      end

      context "when documents_consistent is not determined" do
        let(:consistency_checklist) do
          build(
            :consistency_checklist,
            :complete,
            description_matches_documents: :yes,
            documents_consistent: :to_be_determined,
            proposal_details_match_documents: :yes
          )
        end

        it "returns false" do
          expect(consistency_checklist.valid?).to be(false)
        end

        it "sets error message" do
          consistency_checklist.valid?

          expect(
            consistency_checklist.errors.messages[:documents_consistent]
          ).to contain_exactly(
            "Determine whether the plans are consistent with each other"
          )
        end
      end

      context "when all checks are determined" do
        let(:consistency_checklist) do
          build(
            :consistency_checklist,
            :complete,
            :all_checks_assessed
          )
        end

        it "returns true" do
          expect(consistency_checklist.valid?).to be(true)
        end
      end
    end

    context "when status is 'in_assessment'" do
      let(:consistency_checklist) do
        build(
          :consistency_checklist,
          :in_assessment,
          :all_checks_assessed,
          planning_application: planning_application
        )
      end

      context "when there are open description change requests" do
        before do
          create(
            :description_change_validation_request,
            :open,
            planning_application: planning_application
          )
        end

        it "returns true" do
          expect(consistency_checklist.valid?).to be(true)
        end
      end

      context "when there are open additional document requests" do
        before do
          create(
            :additional_document_validation_request,
            :open,
            planning_application: planning_application
          )
        end

        it "returns true" do
          expect(consistency_checklist.valid?).to be(true)
        end
      end

      context "when description_matches_documents is not determined" do
        let(:consistency_checklist) do
          build(
            :consistency_checklist,
            :in_assessment,
            description_matches_documents: :to_be_determined,
            documents_consistent: :yes,
            proposal_details_match_documents: :yes
          )
        end

        it "returns true" do
          expect(consistency_checklist.valid?).to be(true)
        end
      end

      context "when proposal_details_match_documents is not determined" do
        let(:consistency_checklist) do
          build(
            :consistency_checklist,
            :in_assessment,
            description_matches_documents: :yes,
            documents_consistent: :yes,
            proposal_details_match_documents: :to_be_determined
          )
        end

        it "returns true" do
          expect(consistency_checklist.valid?).to be(true)
        end
      end

      context "when documents_consistent is not determined" do
        let(:consistency_checklist) do
          build(
            :consistency_checklist,
            :in_assessment,
            description_matches_documents: :yes,
            documents_consistent: :to_be_determined,
            proposal_details_match_documents: :yes
          )
        end

        it "returns true" do
          expect(consistency_checklist.valid?).to be(true)
        end
      end
    end
  end
end
