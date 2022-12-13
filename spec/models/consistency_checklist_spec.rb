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

      context "when there are open red line boundary requests" do
        before do
          create(
            :red_line_boundary_change_validation_request,
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
            consistency_checklist.errors.messages[:site_map_correct]
          ).to contain_exactly(
            "Red line boundary change requests must be closed or cancelled"
          )
        end
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
            proposal_details_match_documents: :yes,
            site_map_correct: :yes
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
            proposal_details_match_documents: :to_be_determined,
            site_map_correct: :yes
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
            proposal_details_match_documents: :yes,
            site_map_correct: :yes
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

      context "when site_map_correct is not determined" do
        let(:consistency_checklist) do
          build(
            :consistency_checklist,
            :complete,
            description_matches_documents: :yes,
            documents_consistent: :to_be_determined,
            proposal_details_match_documents: :yes,
            site_map_correct: :to_be_determined
          )
        end

        it "returns false" do
          expect(consistency_checklist.valid?).to be(false)
        end

        it "sets error message" do
          consistency_checklist.valid?

          expect(
            consistency_checklist.errors.messages[:site_map_correct]
          ).to contain_exactly(
            "Determine whether the red line on the site map is correct"
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

      context "when there are open red line boundary requests" do
        before do
          create(
            :red_line_boundary_change_validation_request,
            :open,
            planning_application: planning_application
          )
        end

        it "returns false" do
          expect(consistency_checklist.valid?).to be(true)
        end
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

  describe "#open_red_line_boundary_change_requests?" do
    let(:planning_application) { create(:planning_application) }

    let(:consistency_checklist) do
      create(:consistency_checklist, planning_application: planning_application)
    end

    context "when there are no open requests" do
      it "returns false" do
        expect(
          consistency_checklist.open_red_line_boundary_change_requests?
        ).to be(
          false
        )
      end
    end

    context "when there are open requests" do
      before do
        create(
          :red_line_boundary_change_validation_request,
          planning_application: planning_application
        )
      end

      it "returns true" do
        expect(
          consistency_checklist.open_red_line_boundary_change_requests?
        ).to be(
          true
        )
      end
    end
  end

  describe "#open_additional_document_requests?" do
    let(:planning_application) { create(:planning_application) }

    let(:consistency_checklist) do
      create(:consistency_checklist, planning_application: planning_application)
    end

    context "when there are no open requests" do
      it "returns false" do
        expect(
          consistency_checklist.open_additional_document_requests?
        ).to be(
          false
        )
      end
    end

    context "when there are open requests" do
      before do
        create(
          :additional_document_validation_request,
          planning_application: planning_application
        )
      end

      it "returns true" do
        expect(
          consistency_checklist.open_additional_document_requests?
        ).to be(
          true
        )
      end
    end
  end

  describe "#open_description_change_requests?" do
    let(:planning_application) { create(:planning_application) }

    let(:consistency_checklist) do
      create(:consistency_checklist, planning_application: planning_application)
    end

    context "when there are no open requests" do
      it "returns false" do
        expect(
          consistency_checklist.open_description_change_requests?
        ).to be(
          false
        )
      end
    end

    context "when there are open requests" do
      before do
        create(
          :description_change_validation_request,
          planning_application: planning_application
        )
      end

      it "returns true" do
        expect(
          consistency_checklist.open_description_change_requests?
        ).to be(
          true
        )
      end
    end
  end

  describe "#default_description_matches_documents_to_no?" do
    let(:planning_application) { create(:planning_application) }

    let(:consistency_checklist) do
      create(
        :consistency_checklist,
        planning_application: planning_application,
        description_matches_documents: description_matches_documents
      )
    end

    context "when value is not 'no' and there are no open description change requests" do
      let(:description_matches_documents) { :yes }

      it "returns false" do
        expect(
          consistency_checklist.default_description_matches_documents_to_no?
        ).to be(
          false
        )
      end
    end

    context "when value is 'no'" do
      let(:description_matches_documents) { :no }

      it "returns true" do
        expect(
          consistency_checklist.default_description_matches_documents_to_no?
        ).to be(
          true
        )
      end
    end

    context "when there are open description change requests" do
      let(:description_matches_documents) { :yes }

      before do
        create(
          :description_change_validation_request,
          planning_application: planning_application
        )
      end

      it "returns true" do
        expect(
          consistency_checklist.default_description_matches_documents_to_no?
        ).to be(
          true
        )
      end
    end
  end

  describe "#default_documents_consistent_to_no?" do
    let(:planning_application) { create(:planning_application) }

    let(:consistency_checklist) do
      create(
        :consistency_checklist,
        planning_application: planning_application,
        documents_consistent: documents_consistent
      )
    end

    context "when value is not 'no' and there are no open description change requests" do
      let(:documents_consistent) { :yes }

      it "returns false" do
        expect(
          consistency_checklist.default_documents_consistent_to_no?
        ).to be(
          false
        )
      end
    end

    context "when value is 'no'" do
      let(:documents_consistent) { :no }

      it "returns true" do
        expect(
          consistency_checklist.default_documents_consistent_to_no?
        ).to be(
          true
        )
      end
    end

    context "when there are open description change requests" do
      let(:documents_consistent) { :yes }

      before do
        create(
          :additional_document_validation_request,
          planning_application: planning_application
        )
      end

      it "returns true" do
        expect(
          consistency_checklist.default_documents_consistent_to_no?
        ).to be(
          true
        )
      end
    end
  end

  describe "#default_site_map_correct_to_no?" do
    let(:planning_application) { create(:planning_application) }

    let(:consistency_checklist) do
      create(
        :consistency_checklist,
        planning_application: planning_application,
        site_map_correct: site_map_correct
      )
    end

    context "when value is not 'no' and there are no open description change requests" do
      let(:site_map_correct) { :yes }

      it "returns false" do
        expect(
          consistency_checklist.default_site_map_correct_to_no?
        ).to be(
          false
        )
      end
    end

    context "when value is 'no'" do
      let(:site_map_correct) { :no }

      it "returns true" do
        expect(
          consistency_checklist.default_site_map_correct_to_no?
        ).to be(
          true
        )
      end
    end

    context "when there are open description change requests" do
      let(:site_map_correct) { :yes }

      before do
        create(
          :red_line_boundary_change_validation_request,
          planning_application: planning_application
        )
      end

      it "returns true" do
        expect(
          consistency_checklist.default_site_map_correct_to_no?
        ).to be(
          true
        )
      end
    end
  end
end
