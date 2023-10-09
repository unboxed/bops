# frozen_string_literal: true

module PlanningApplications
  class SiteVisitsController < AuthenticationController
    before_action :set_planning_application
    before_action :set_consultation
    before_action :set_objected_neighbour_responses, only: %i[index new]
    before_action :set_site_visit, only: [:show]

    def index
      @site_visits = @consultation.site_visits.by_created_at_desc.includes(:created_by)

      respond_to do |format|
        format.html
      end
    end

    def show
      respond_to do |format|
        format.html
      end
    end

    def new
      @site_visit = @consultation.site_visits.new

      respond_to do |format|
        format.html
      end
    end

    def create
      @site_visit = @consultation.site_visits.new(site_visit_params)
      @site_visit.created_by = current_user
      @site_visit.status = "complete"

      respond_to do |format|
        if @site_visit.save
          format.html do
            redirect_to planning_application_consultations_path(@planning_application), notice: t(".success")
          end
        else
          set_objected_neighbour_responses
          format.html { render :new }
        end
      end
    end

    private

    def site_visit_params
      params.require(:site_visit).permit(:decision, :comment, :visited_at, :neighbour_id).merge(documents_attributes:)
    end

    def documents_attributes
      files = params.dig(:site_visit, :documents_attributes, "0", :files).compact_blank
      files.map.with_index do |file, i|
        [i.to_s, { file:, planning_application_id: @planning_application.id, tags: ["Site Visit"] }]
      end.to_h
    end

    def set_objected_neighbour_responses
      @objected_neighbour_responses = @consultation.neighbour_responses.objection
    end

    def set_site_visit
      @site_visit = @consultation.site_visits.find(params[:id])
    end
  end
end
