# frozen_string_literal: true

module PlanningApplications
  module Assessment
    module Informatives
      class ItemsController < BaseController
        before_action :set_informative_set
        before_action :set_informative

        def destroy
          respond_to do |format|
            format.html do
              if @informative.destroy
                redirect_to redirect_path, notice: t(".success")
              else
                redirect_to redirect_path, notice: t(".failure")
              end
            end
          end
        end

        private

        def set_informative_set
          @informative_set = @planning_application.informative_set
        end

        def set_informative
          @informative = @informative_set.informatives.find(params[:id])
        end

        def informative_params
          params.require(:informative).permit(:title, :text)
        end

        def redirect_path
          params[:redirect_to]
        end
      end
    end
  end
end
