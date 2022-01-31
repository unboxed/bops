# frozen_string_literal: true

module Public
  class PlanningGuidesController < ApplicationController
    skip_before_action :set_current_user

    BASE_URL = "public/planning_guides/"

    def show
      respond_to do |format|
        format.html do
          if params[:type]
            render template: "#{BASE_URL}#{params[:type]}/#{params[:page]}"
          else
            render template: "#{BASE_URL}#{params[:page]}"
          end
        end
      end
    end
  end
end
