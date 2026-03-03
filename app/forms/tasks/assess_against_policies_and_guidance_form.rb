# frozen_string_literal: true

module Tasks
  class AssessAgainstPoliciesAndGuidanceForm < Form
    self.task_actions = %w[save_and_complete save_draft add_consideration update_consideration]

    after_initialize do
      @consideration_set = planning_application.consideration_set
      @considerations = @consideration_set.considerations.select(&:persisted?)
      @consideration = @consideration_set.considerations.new
      @review = @consideration_set.current_review
    end

    attr_reader :consideration_set, :considerations, :consideration, :review

    def consideration_for_edit
      @consideration_for_edit ||= consideration_set.considerations.find(params[:id]) if params[:id].present?
    end

    def url(options = {})
      if params[:id].present?
        task_component_path(planning_application, slug: task.full_slug, id: params[:id])
      else
        super
      end
    end

    private

    def update_consideration
      consideration_params = @params[:consideration]&.permit(
        :policy_area, :assessment, :conclusion,
        policy_references_attributes: [:code, :description, :url],
        policy_guidance_attributes: [:description, :url]
      ) || {}

      consideration_for_edit.assign_attributes(consideration_params)
      consideration_for_edit.submitted_by = Current.user

      consideration_for_edit.valid?(:assess) && consideration_for_edit.save
    end

    def add_consideration
      consideration_params = @params[:consideration]&.permit(
        :policy_area, :assessment, :conclusion,
        policy_references_attributes: [:code, :description, :url],
        policy_guidance_attributes: [:description, :url]
      ) || {}

      @consideration.assign_attributes(consideration_params)
      @consideration.submitted_by = Current.user

      if @consideration.valid?(:assess) && @consideration.save
        @considerations = @consideration_set.considerations.select(&:persisted?)
        @consideration = @consideration_set.considerations.new
        true
      else
        false
      end
    end
  end
end
