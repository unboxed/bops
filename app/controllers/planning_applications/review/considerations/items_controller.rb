# frozen_string_literal: true

module PlanningApplications
  module Review
    module Considerations
      class ItemsController < BaseController
        before_action :set_consideration_set
        before_action :set_consideration

        def edit
          respond_to do |format|
            format.html
          end
        end

        def update
          respond_to do |format|
            format.html do
              if @consideration.update(consideration_params)
                redirect_to planning_application_review_tasks_path(@planning_application, anchor: "considerations_section"), notice: t(".success")
              else
                render :edit
              end
            end
          end
        end

        private

        def set_consideration_set
          @consideration_set = @planning_application.consideration_set
        end

        def set_consideration
          @consideration = @consideration_set.considerations.find(params[:id])
        end

        def consideration_params
          params.require(:consideration).permit(
            :policy_area, :assessment, :conclusion,
            policy_references_attributes: %i[code description url],
            policy_guidance_attributes: %i[description url]
          ).merge(reviewer_edited: true)
        end
      end
    end
  end
end
