# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplications::Assessment::RecommendationsController do
  describe "#update" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:reviewer) do
      create(:user, :reviewer, local_authority:)
    end

    let(:planning_application) do
      create(
        :planning_application,
        :awaiting_determination,
        local_authority:
      )
    end

    let!(:recommendation) do
      create(
        :recommendation,
        :assessment_complete,
        submitted: true,
        planning_application:
      )
    end

    let(:recommendation_params) do
      {challenged: false, reviewer_comment: "Comment"}
    end

    let(:params) do
      {
        commit: I18n.t("form_actions.save_and_come_back_later"),
        planning_application_id: planning_application.id,
        id: recommendation.id,
        recommendation: recommendation_params
      }
    end

    before do
      @request.host = "planx.example.com"
      sign_in(reviewer)
    end

    it "updates recommendation" do
      put(:update, params:)

      expect(recommendation.reload).to have_attributes(
        recommendation_params.merge(status: "review_in_progress")
      )
    end

    it "redirects to planning application path" do
      post(:update, params:)

      expect(response).to redirect_to(
        planning_application_review_tasks_path(planning_application)
      )
    end

    context "when recommendation in invalid" do
      before do
        allow_any_instance_of(Recommendation)
          .to receive(:valid?)
          .and_return(false)
      end

      it "renders edit" do
        post(:update, params:)

        expect(response).to render_template(:edit)
      end
    end
  end
end