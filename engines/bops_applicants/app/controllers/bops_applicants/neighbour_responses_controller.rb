# frozen_string_literal: true

module BopsApplicants
  class NeighbourResponsesController < ApplicationController
    before_action :set_planning_application
    before_action :redirect_to_application_page, if: :application_decided?
    before_action :set_neighbour_response_form

    def new
      respond_to do |format|
        format.html
      end
    end

    def create
      respond_to do |format|
        if @neighbour_response.save
          format.html { redirect_to [:thank_you, @planning_application, @neighbour_response] }
        elsif @neighbour_response.failed?
          format.html { render :new, alert: t(".failure") }
        else
          format.html { render :new }
        end
      end
    end

    def start
      respond_to do |format|
        format.html
      end
    end

    def thank_you
      respond_to do |format|
        format.html
      end
    end

    private

    def planning_applications_scope
      current_local_authority.planning_applications.published
    end

    def planning_application_param
      params.fetch(:planning_application_reference)
    end

    def redirect_to_application_page
      redirect_to planning_application_url(@planning_application)
    end

    def application_decided?
      @planning_application.decision?
    end

    def set_neighbour_response_form
      @neighbour_response = BopsApplicants::NeighbourResponseForm.new(@planning_application, params)
    end
  end
end
