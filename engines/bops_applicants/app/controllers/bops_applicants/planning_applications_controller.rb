# frozen_string_literal: true

module BopsApplicants
  class PlanningApplicationsController < ApplicationController
    before_action :set_planning_application
    before_action :set_documents
    before_action :set_consultation
    before_action :set_neighbour_comments
    before_action :set_consultee_comments

    def show
      respond_to do |format|
        format.html
      end
    end

    private

    def planning_applications_scope
      current_local_authority.planning_applications.published
    end

    def planning_application_param
      params.fetch(:reference)
    end

    def set_documents
      @documents = @planning_application.documents.active.for_publication
    end

    def set_consultation
      @consultation = @planning_application.consultation
    end

    def set_neighbour_comments
      @neighbour_comments = @consultation.neighbour_responses.redacted
    end

    def set_consultee_comments
      @consultee_comments = @consultation.consultee_responses.redacted
    end
  end
end
