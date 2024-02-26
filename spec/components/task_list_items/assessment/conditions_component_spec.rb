# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::Assessment::ConditionsComponent, type: :component do
  let(:planning_application) { create(:planning_application, :in_assessment) }

  context "when conditions" do
    let(:condition_set) { create(:condition_set, planning_application:, pre_commencement: false) }

    before do
      render_inline(
        described_class.new(
          condition_set:
        )
      )
    end

    context "when the assessment has not been started" do
      before do
        render_inline(
          described_class.new(
            condition_set:
          )
        )
      end

      it "renders link to new assessment detail page" do
        expect(page).to have_link(
          "Add conditions",
          href: "/planning_applications/#{planning_application.id}/assessment/conditions"
        )
      end

      it "renders correct status tag" do
        expect(page).to have_content("Not started")
      end
    end

    context "when review status is 'complete'" do
      before do
        create(:review, owner: condition_set, status: "complete")

        render_inline(
          described_class.new(
            condition_set:
          )
        )
      end

      it "renders link to permitted development right review page" do
        expect(page).to have_link(
          "Add conditions",
          href: "/planning_applications/#{planning_application.id}/assessment/conditions"
        )
      end

      it "renders correct status tag" do
        expect(page).to have_content("Complete")
      end
    end

    context "when review status is not 'complete'" do
      before do
        create(:review, owner: condition_set, status: "in_progress")

        render_inline(
          described_class.new(
            condition_set:
          )
        )
      end

      it "renders link to edit permitted development right review page" do
        expect(page).to have_link(
          "Add conditions",
          href: "/planning_applications/#{planning_application.id}/assessment/conditions"
        )
      end

      it "renders correct status tag" do
        expect(page).to have_content("In progress")
      end
    end
  end

  context "when pre-commencement conditions" do
    let(:condition_set) { create(:condition_set, planning_application:, pre_commencement: true) }

    context "when the assessment has not been started" do
      before do
        render_inline(
          described_class.new(
            condition_set:
          )
        )
      end

      it "renders link to new assessment detail page" do
        expect(page).to have_link(
          "Add pre-commencement conditions",
          href: "/planning_applications/#{planning_application.id}/assessment/conditions?pre_commencement=true"
        )
      end

      it "renders correct status tag" do
        expect(page).to have_content("Not started")
      end
    end

    context "when review status is 'complete'" do
      before do
        create(:review, owner: condition_set, status: "complete")

        render_inline(
          described_class.new(
            condition_set:
          )
        )
      end

      it "renders link to permitted development right review page" do
        expect(page).to have_link(
          "Add pre-commencement conditions",
          href: "/planning_applications/#{planning_application.id}/assessment/conditions?pre_commencement=true"
        )
      end

      it "renders correct status tag" do
        expect(page).to have_content("Complete")
      end
    end

    context "when review status is not 'complete'" do
      before do
        create(:review, owner: condition_set, status: "in_progress")

        render_inline(
          described_class.new(
            condition_set:
          )
        )
      end

      it "renders link to edit permitted development right review page" do
        expect(page).to have_link(
          "Add pre-commencement conditions",
          href: "/planning_applications/#{planning_application.id}/assessment/conditions?pre_commencement=true"
        )
      end

      it "renders correct status tag" do
        expect(page).to have_content("In progress")
      end
    end

    context "when applicant has responded to validation requests" do
      before do
        create(:review, owner: condition_set, status: "in_progress")
        condition = create(:condition, condition_set:)
        create(:pre_commencement_condition_validation_request, condition:, state: "closed", approved: false)

        render_inline(
          described_class.new(
            condition_set:
          )
        )
      end

      it "renders link to edit permitted development right review page" do
        expect(page).to have_link(
          "Add pre-commencement conditions",
          href: "/planning_applications/#{planning_application.id}/assessment/conditions?pre_commencement=true"
        )
      end

      it "renders correct status tag" do
        expect(page).to have_content("Updated")
      end
    end
  end
end
