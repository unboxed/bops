# frozen_string_literal: true

module BopsApi
  class ApplicationController < BopsCore::ApplicationController
    include ErrorHandler
    include SchemaValidation

    protect_from_forgery with: :null_session, prepend: true
    wrap_parameters false

    before_action :require_local_authority!

    private

    def find_planning_application(param)
      if /\A\d{2}-\d{5}-[A-Za-z0-9]+\z/.match?(param)
        planning_applications_scope.find_by!(reference: param)
      else
        planning_applications_scope.find(Integer(param))
      end
    rescue ArgumentError
      raise ActionController::BadRequest, "Invalid planning application reference or id: #{param.inspect}"
    end

    def search_params
      params.permit(:page,
        :maxresults,
        :q,
        :sortBy,
        :orderBy,
        :receivedAtFrom,
        :receivedAtTo,
        :validatedAtFrom,
        :validatedAtTo,
        :publishedAtFrom,
        :publishedAtTo,
        :consultationEndDateFrom,
        :consultationEndDateTo,
        :councilDecision,
        :alternativeReference,
        applicationStatus: [],
        applicationType: [])
    end

    def search_service(scope = planning_applications_scope.by_latest_received_and_created)
      @search_service ||= Application::SearchService.new(scope, search_params)
    end
  end
end
