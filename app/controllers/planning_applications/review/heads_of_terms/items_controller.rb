# frozen_string_literal: true

module PlanningApplications
  module Review
    module HeadsOfTerms
      class ItemsController < BaseController
        before_action :set_heads_of_terms
        before_action :set_terms
        before_action :set_term

        def edit
          respond_to do |format|
            format.html
          end
        end

        def update
          respond_to do |format|
            format.html do
              if @term.update(term_params)
                redirect_to planning_application_review_tasks_path(@planning_application, anchor: "review-heads-of-terms"), notice: t(".success")
              else
                render :edit
              end
            end
          end
        end

        private

        def set_heads_of_terms
          @heads_of_terms = @planning_application.heads_of_term
        end

        def set_terms
          @terms = @heads_of_terms.terms
        end

        def set_term
          @term = @terms.find(params[:id])
        end

        def term_params
          params.require(:term).permit(:title, :text).merge(reviewer_edited: true)
        end
      end
    end
  end
end
