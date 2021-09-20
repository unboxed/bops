class Api::V1::ValidationRequestsController < Api::V1::ApplicationController
  before_action :check_token_and_set_application, only: %i[index], if: :json_request?

  def index; end

private

  def check_token_and_set_application
    @planning_application = current_local_authority.planning_applications.find_by(id: params[:planning_application_id])
    if params[:change_access_id] != @planning_application.change_access_id
      render json: {}, status: :unauthorized
    else
      @planning_application
    end
  end

  def check_file_size
    if params[:new_file].size > 30.megabytes
      render json: { "message": "The file must be 30MB or less" }, status: :bad_request
    end
  end
end
