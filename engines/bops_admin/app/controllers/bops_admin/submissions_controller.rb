# frozen_string_literal: true

module BopsAdmin
  class SubmissionsController < ApplicationController
    before_action :set_submissions, only: %i[index]
    before_action :set_submission, only: %i[show]

    rescue_from Pagy::OverflowError do
      redirect_to submissions_path
    end

    def index
      respond_to do |format|
        format.html
      end
    end

    def show
      @planning_application = @submission.planning_application
      respond_to do |format|
        format.html
      end
    end

    private

    def set_submissions
      @pagy, @submissions = pagy(current_local_authority.submissions.by_created_at_desc, limit: 10)
    end

    def set_submission
      @submission = current_local_authority.submissions.includes(planning_application: :documents).find(params[:id])
    end
  end
end
