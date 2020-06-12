# frozen_string_literal: true

class Api::V1::PlanningApplicationsController < Api::V1::ApplicationController
  before_action :set_cors_headers, only: %i[index], if: :json_request?

  def index
    @planning_applications = PlanningApplication.determined

    respond_to(:json)
  end
end
