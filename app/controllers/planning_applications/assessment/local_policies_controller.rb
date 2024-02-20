# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class LocalPoliciesController < AuthenticationController
      include CommitMatchable

      before_action :set_planning_application
      before_action :set_local_policy, only: %i[show edit update]
      before_action :set_local_policy_areas, only: %i[new edit]
      before_action :set_reviewer_comment, only: %i[edit new show]

      def show
      end

      def new
        @local_policy = @planning_application.build_local_policy
      end

      def edit
      end

      def create
        @local_policy = @planning_application.build_local_policy(assign_params.except(:areas))

        if @local_policy.save
          redirect_to planning_application_assessment_tasks_path(@planning_application),
            notice: I18n.t("local_policies.successfully_created")
        else
          set_local_policy_areas
          render :new
        end
      end

      def update
        if @local_policy.update(assign_params.except(:areas))
          redirect_to planning_application_assessment_tasks_path(@planning_application),
            notice: I18n.t("local_policies.successfully_updated")
        else
          set_local_policy_areas
          render :edit
        end
      end

      def add_local_policy_areas
        set_local_policy
        local_policy_area = LocalPolicyArea.create!(area: policy_params[:area], policies: policy_params[:policies], assessment: policy_params[:assessment], enabled: policy_params[:enabled], local_policy: @local_policy)

        if local_policy_area.save
          set_local_policy_areas
          render :edit, notice: 'Policy was successfully added'
        else
          set_local_policy_areas
          render :edit
        end
      end

      private

      def set_local_policy
        @local_policy = @planning_application.local_policy
      end

      def status
        mark_as_complete? ? "complete" : "in_progress"
      end

      def local_policy_params
        params.require(:local_policy)
          .permit(
            areas: [],
            local_policy_areas_attributes: %i[area policies guidance assessment enabled id]
          )
          .to_h.merge(reviews_attributes: [status:, id: (@local_policy&.current_review&.id if !mark_as_complete?)])
      end

      def policy_params
        params.permit([:area, :id, :policies, :assessment, :guidance, :enabled])
      end

      def assign_params
        local_policy_areas_attributes = local_policy_params[:local_policy_areas_attributes].select do |_key, value|
          value[:enabled].present? || value[:policies].present? || value[:guidance].present? || value[:assessment].present?
        end

        new_params = local_policy_params

        new_params[:local_policy_areas_attributes] = local_policy_areas_attributes
        new_params
      end

      def set_reviewer_comment
        @reviewer_comment = @planning_application&.local_policy&.review_local_polices_with_comments&.last
      end

      def set_local_policy_areas
        areas = @local_policy.present? ? @local_policy.local_policy_areas.map(&:area) : []
        current_local_policy_areas = @local_policy.present? ? @local_policy.local_policy_areas : []

        local_policy_areas = (LocalPolicy::AREAS - areas).map do |area|
          LocalPolicyArea.new(area:)
        end

        @local_policy_areas = (local_policy_areas + current_local_policy_areas).sort_by(&:area)
      end
    end
  end
end
