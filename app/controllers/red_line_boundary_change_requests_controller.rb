class RedLineBoundaryChangeRequestsController < ApplicationController
  before_action :set_planning_application, only: %i[new create show]

  def new
    @red_line_boundary_change_request = @planning_application.red_line_boundary_change_requests.new
  end

  def show
    @red_line_boundary_change_request = @planning_application.red_line_boundary_change_requests.find(params[:id])
  end

  def create
    @red_line_boundary_change_request = RedLineBoundaryChangeRequest.new(new_geojson: transform_geojson(red_line_boundary_change_request_params[:new_geojson]),
                                                                         planning_application_id: @planning_application.id,
                                                                         reason: red_line_boundary_change_request_params[:reason])
    @red_line_boundary_change_request.user = current_user
    @current_local_authority = current_local_authority

    if @red_line_boundary_change_request.save
      send_change_request_email
      flash[:notice] = "Change request for red line boundary successfully sent."
      redirect_to planning_application_change_requests_path(@planning_application)
    else
      render :new
    end
  end

private

  def red_line_boundary_change_request_params
    params.require(:red_line_boundary_change_request).permit(:new_geojson, :reason)
  end

  def transform_geojson(lat_longs)
    new_lat_long = lat_longs.gsub("LatLng(", "").gsub(")", "").split(",").each_slice(2).to_a
    new_coordinates = new_lat_long.each do |chunk|
      chunk.map! { |e| e.to_f.round(8) }.sort!
    end
    new_hash = { type: "Feature", geometry: { type: "Polygon", coordinates: [new_coordinates] } }.to_json
    new_hash
  end

  def set_planning_application
    @planning_application = PlanningApplication.find(params[:planning_application_id])
  end

  def send_change_request_email
    PlanningApplicationMailer.change_request_mail(
      @planning_application,
      @red_line_boundary_change_request,
    ).deliver_now
  end
end
