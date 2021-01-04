# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationHelper, type: :helper do
  describe "#days_color" do
    it "returns the correct colour for less than 6" do
      expect(days_color(3)).to eq("red")
    end

    it "returns the correct colour for 6..10" do
      expect(days_color(7)).to eq("yellow")
    end

    it "returns the correct colour for 11 and over" do
      expect(days_color(14)).to eq("green")
    end
  end

  describe "#assessor_decision_path" do
    let!(:planning_application) { create :planning_application }

    context "without decision" do
      it "returns to new decision" do
        expect(assessor_decision_path(planning_application)).to eq(new_planning_application_decision_path(planning_application))
      end
    end

    describe "#list_constraints" do
      let(:application_with_constraints) do
        create :planning_application,
               constraints: '{"conservation_area": false,"article4_area": true,"scheduled_monument": false }'
      end

      let(:application_with_false_constraints) do
        create :planning_application,
               constraints: '{"conservation_area": false,"article4_area": false,"scheduled_monument": false }'
      end

      let(:application_without_constraints) { create :planning_application, constraints: "{}" }

      it "creates constraints list correctly" do
        expect(list_constraints(application_with_constraints.constraints)).to eq(%w[article4_area])
      end

      it "can handle an empty constraints list" do
        expect(list_constraints(application_without_constraints.constraints)).to be_empty
      end

      it "returns an empty array if all constraints are false" do
        expect(list_constraints(application_with_false_constraints.constraints)).to be_empty
      end
    end

    context "with decision" do
      let(:assessor) { create :user, :assessor }
      let(:assessor_decision) { create(:decision, :granted, user: assessor) }

      before do
        planning_application.decisions << assessor_decision
        planning_application.reload
      end

      context "in assessment" do
        it "returns to edit decision" do
          expect(assessor_decision_path(planning_application)).to eq(edit_planning_application_decision_path(planning_application, planning_application.assessor_decision))
        end
      end

      context "awaiting determination" do
        before { planning_application.assess }

        it "returns to show decision" do
          expect(assessor_decision_path(planning_application)).to eq(planning_application_decision_path(planning_application, planning_application.assessor_decision))
        end
      end

      context "awaiting correction" do
        before do
          planning_application.assess!
          planning_application.reload
        end

        it "returns to edit decision" do
          planning_application.request_correction!
          expect(assessor_decision_path(planning_application)).to eq(edit_planning_application_decision_path(planning_application, planning_application.assessor_decision))
        end
      end

      context "determined" do
        before do
          planning_application.assess!
          planning_application.reload
        end

        it "returns to show decision" do
          planning_application.determine!
          expect(assessor_decision_path(planning_application)).to eq(planning_application_decision_path(planning_application, planning_application.assessor_decision))
        end
      end
    end
  end

  describe "#reviewer_decision_path" do
    let!(:planning_application) { create :planning_application, :awaiting_determination }

    context "without decision" do
      it "returns to new decision" do
        expect(reviewer_decision_path(planning_application)).to eq(new_planning_application_decision_path(planning_application))
      end
    end

    context "with decision" do
      let(:reviewer) { create :user, :reviewer }
      let(:reviewer_decision) { create(:decision, :refused_private_comment, user: reviewer) }

      before do
        planning_application.decisions << reviewer_decision
        planning_application.reload
      end

      context "awaiting determination" do
        it "returns to show decision" do
          expect(reviewer_decision_path(planning_application)).to eq(edit_planning_application_decision_path(planning_application, planning_application.reviewer_decision))
        end
      end

      context "awaiting correction" do
        before { planning_application.request_correction }

        it "returns to edit decision" do
          expect(reviewer_decision_path(planning_application)).to eq(planning_application_decision_path(planning_application, planning_application.reviewer_decision))
        end
      end

      context "determined" do
        before { planning_application.determine }

        it "returns to show decision" do
          expect(reviewer_decision_path(planning_application)).to eq(planning_application_decision_path(planning_application, planning_application.reviewer_decision))
        end
      end
    end
  end

  describe "#display_decision_status" do
    let(:planning_application) { create :planning_application }

    context "refused" do
      let(:reviewer) { create :user, :reviewer }
      let(:reviewer_decision) { create(:decision, :refused_private_comment, user: reviewer) }

      before do
        planning_application.decisions << reviewer_decision
        planning_application.assess!
        planning_application.reload
        planning_application.determine!
      end

      it "returns correct values when application is refused" do
        expect(display_status(planning_application)[:decision]).to eql("Refused")
        expect(display_status(planning_application)[:color]).to eql("red")
      end
    end

    context "granted" do
      let(:reviewer) { create :user, :reviewer }
      let(:reviewer_decision) { create(:decision, :granted, user: reviewer) }

      before do
        planning_application.decisions << reviewer_decision
        planning_application.assess!
        planning_application.reload
        planning_application.determine!
      end

      it "returns correct values when application is granted" do
        expect(display_status(planning_application)[:decision]).to eql("Granted")
        expect(display_status(planning_application)[:color]).to eql("green")
      end
    end
  end

  describe "#display_status" do
    let(:planning_application) { create :planning_application }

    it "returns correct values when application is withdrawn" do
      planning_application.withdraw!
      expect(display_status(planning_application)[:decision]).to eql("withdrawn")
      expect(display_status(planning_application)[:color]).to eql("grey")
    end

    it "returns correct values when application is returned" do
      planning_application.return!
      expect(display_status(planning_application)[:decision]).to eql("returned")
      expect(display_status(planning_application)[:color]).to eql("grey")
    end
  end
end
