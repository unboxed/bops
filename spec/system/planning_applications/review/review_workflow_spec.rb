# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Review workflow consistency", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:, name: "Alice Smith") }
  let(:reviewer) { create(:user, :reviewer, local_authority:, name: "Bella Jones") }
  let(:reference) { planning_application.reference }
  let(:comment_text) { "Please revise this" }

  let(:assessor_task_slug) { nil }
  let(:revised_entry) { nil }

  shared_examples "a consistent review task" do
    it "rejects, returns to assessor with visible comment, and accepts" do
      sign_in(reviewer)
      visit "/planning_applications/#{reference}/review/tasks"
      within("##{section_id}") { expect(page).to have_content("Not started") }

      find("##{section_id} .bops-task-accordion__section-header button").click
      within("##{section_id}") do
        choose "Return with comments"
        fill_in "Add a comment", with: comment_text
        click_button "Save and mark as complete"

        expect(page).to have_content("Awaiting changes")
        expect(page).to have_css(".comment-component", text: comment_text)
      end

      click_link "Sign off recommendation"
      choose "No (return the case for assessment)"
      fill_in "Explain to the officer why the case is being returned", with: "Returned for rework"
      click_button "Save and mark as complete"
      expect(planning_application.reload.status).to eq("to_be_reviewed")

      if assessor_task_slug
        switch_user(assessor)

        visit "/planning_applications/#{reference}/#{assessor_task_slug}"
        within(".comment-component") do
          expect(page).to have_content("Reviewer comment")
          expect(page).to have_content(comment_text)
        end

        if revised_entry
          find("textarea").set(revised_entry)
          click_button "Save and mark as complete"
        end

        switch_user(reviewer)
        visit "/planning_applications/#{reference}/review/tasks"

        if revised_entry
          within("##{section_id}") { expect(page).to have_content("Updated") }
        end
      end

      find("##{section_id} .bops-task-accordion__section-header button").click
      within("##{section_id}") do
        choose accept_label
        click_button "Save and mark as complete"

        expect(page).to have_content("Completed")
      end
    end
  end

  context "for a planning permission application" do
    let(:planning_application) do
      create(:planning_application, :awaiting_determination, :planning_permission,
        local_authority:, decision: :granted, user: assessor)
    end

    before { create(:recommendation, status: "assessment_complete", planning_application:) }

    describe "summary of works" do
      let(:section_id) { "summary_of_work_section" }
      let(:accept_label) { "Accept" }
      let(:assessor_task_slug) { "check-and-assess/assessment-summaries/summary-of-works" }
      let(:revised_entry) { "Updated summary" }

      before do
        create(:assessment_detail, :summary_of_work,
          assessment_status: :complete, planning_application:, user: assessor,
          entry: "Original summary")
      end

      it_behaves_like "a consistent review task"
    end

    describe "site description" do
      let(:section_id) { "site_description_section" }
      let(:accept_label) { "Accept" }
      let(:assessor_task_slug) { "check-and-assess/assessment-summaries/site-description" }
      let(:revised_entry) { "Updated site description" }

      before do
        create(:assessment_detail, :site_description,
          assessment_status: :complete, planning_application:, user: assessor,
          entry: "Original site description")
      end

      it_behaves_like "a consistent review task"
    end

    describe "additional evidence" do
      let(:section_id) { "additional_evidence_section" }
      let(:accept_label) { "Accept" }
      let(:assessor_task_slug) { "check-and-assess/assessment-summaries/other-considerations" }

      before do
        create(:assessment_detail, :additional_evidence,
          assessment_status: :complete, planning_application:, user: assessor,
          entry: "Original additional evidence")
      end

      it_behaves_like "a consistent review task"
    end

    describe "consultation summary" do
      let(:section_id) { "consultation_summary_section" }
      let(:accept_label) { "Accept" }
      let(:assessor_task_slug) { "check-and-assess/assessment-summaries/summary-of-consultation" }
      let(:revised_entry) { "Updated consultation summary" }

      before do
        create(:assessment_detail, :consultation_summary,
          assessment_status: :complete, planning_application:, user: assessor,
          entry: "Original consultation summary")
      end

      it_behaves_like "a consistent review task"
    end

    describe "neighbour summary" do
      let(:section_id) { "neighbour_summary_section" }
      let(:accept_label) { "Accept" }
      let(:assessor_task_slug) { "check-and-assess/assessment-summaries/summary-of-neighbour-responses" }

      let!(:neighbour) { create(:neighbour, consultation: planning_application.consultation) }
      let!(:response) { create(:neighbour_response, neighbour:, summary_tag: "objection") }

      before do
        create(:assessment_detail, :neighbour_summary,
          assessment_status: :complete, planning_application:, user: assessor,
          entry: "Original neighbour summary")
      end

      it_behaves_like "a consistent review task"
    end

    describe "amenity" do
      let(:section_id) { "amenity_section" }
      let(:accept_label) { "Accept" }

      before do
        create(:assessment_detail, :amenity,
          assessment_status: :complete, planning_application:, user: assessor,
          entry: "Original amenity assessment")
      end

      it_behaves_like "a consistent review task"
    end

    describe "considerations", :pending do
      let(:section_id) { "review-considerations" }
      let(:accept_label) { "Agree" }
      let(:assessor_task_slug) { "check-and-assess/assess-against-policies-and-guidance/assess-against-policies-and-guidance" }

      let!(:consideration_set) { planning_application.consideration_set || create(:consideration_set, planning_application:) }
      let!(:consideration) { create(:consideration, consideration_set:) }

      before { consideration_set.update_review(status: "complete") }

      it_behaves_like "a consistent review task"
    end

    describe "conditions", :pending do
      let(:section_id) { "review-conditions" }
      let(:accept_label) { "Agree" }
      let(:assessor_task_slug) { "check-and-assess/complete-assessment/add-conditions" }

      let!(:condition_set) { planning_application.condition_set }
      let!(:condition) { create(:condition, condition_set:) }

      before { condition_set.current_review.complete! }

      it_behaves_like "a consistent review task"
    end

    describe "pre-commencement conditions", :pending do
      let(:section_id) { "review-pre-commencement-conditions" }
      let(:accept_label) { "Agree" }
      let(:assessor_task_slug) { "check-and-assess/complete-assessment/add-pre-commencement-conditions" }

      let!(:pcc_set) { planning_application.pre_commencement_condition_set }
      let!(:pcc) { Current.set(user: assessor) { create(:condition, condition_set: pcc_set) } }

      before { pcc_set.current_review.complete! }

      it_behaves_like "a consistent review task"
    end

    describe "informatives", :pending do
      let(:section_id) { "review-informatives" }
      let(:accept_label) { "Agree" }
      let(:assessor_task_slug) { "check-and-assess/complete-assessment/add-informatives" }

      let!(:informative_set) { planning_application.informative_set }
      let!(:informative) { create(:informative, informative_set:) }

      before { informative_set.current_review.update!(status: :complete) }

      it_behaves_like "a consistent review task"
    end

    describe "heads of terms", :pending do
      let(:section_id) { "review-heads-of-terms" }
      let(:accept_label) { "Agree" }
      let(:assessor_task_slug) { "check-and-assess/complete-assessment/add-heads-of-terms" }

      let!(:heads_of_term) { planning_application.heads_of_term }
      let!(:term) { Current.set(user: assessor) { create(:term, heads_of_term:) } }

      before { heads_of_term.current_review.complete! }

      it_behaves_like "a consistent review task"
    end

    describe "check neighbour notifications", :pending do
      let(:section_id) { "review-neighbour-responses" }
      let(:accept_label) { "Agree" }

      before do
        create(:neighbour, consultation: planning_application.consultation)
        Current.set(user: assessor) { planning_application.consultation.create_neighbour_review! }
      end

      it_behaves_like "a consistent review task"
    end

    describe "check publicity", :pending do
      let(:section_id) { "review-publicities" }
      let(:accept_label) { "Agree" }

      let!(:site_notice) { create(:site_notice, planning_application:) }
      let!(:press_notice) { create(:press_notice, planning_application:) }

      it_behaves_like "a consistent review task"
    end
  end

  context "for a prior approval application" do
    let(:planning_application) do
      create(:planning_application, :awaiting_determination, :prior_approval,
        local_authority:, decision: :granted, user: assessor)
    end

    before { create(:recommendation, status: "assessment_complete", planning_application:) }

    describe "permitted development rights", :pending do
      let(:section_id) { "review-permitted-development-rights" }
      let(:accept_label) { "Agree" }
      let(:assessor_task_slug) { "check-and-assess/check-application/permitted-development-rights" }

      let!(:permitted_development_right) do
        create(:permitted_development_right, planning_application:,
          status: :in_progress, removed: true, removed_reason: "Removal reason")
      end

      it_behaves_like "a consistent review task"
    end
  end
end
