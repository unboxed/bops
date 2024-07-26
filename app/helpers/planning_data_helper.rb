# frozen_string_literal: true

module PlanningDataHelper
  PLANNING_DATA_BASE_URL = "https://www.planning.data.gov.uk/"

  def planning_data_entity_url(entity_id)
    "#{PLANNING_DATA_BASE_URL}entity/#{entity_id}"
  end

  def planning_data_map_url(datasets, planning_application)
    uri = URI.join(PLANNING_DATA_BASE_URL, "map/")
    uri.query = URI.encode_www_form({dataset: datasets}) if datasets.any?
    uri.fragment = lat_lon_zoom(planning_application)
    uri.to_s
  end

  private

  def lat_lon_zoom(planning_application)
    "#{planning_application.latitude},#{planning_application.longitude},17"
  end
end
