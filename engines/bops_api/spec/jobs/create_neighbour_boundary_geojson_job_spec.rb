# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::CreateNeighbourBoundaryGeojsonJob, type: :job do
  let!(:planning_application) { create(:planning_application, neighbour_boundary_geojson: nil) }

  before do
    Rails.configuration.os_vector_tiles_api_key = "testtest"
  end

  context "OS places returns addresses" do
    it "creates geojson for planning application" do
      stub_os_places_api_request_for_radius(planning_application.latitude, planning_application.longitude)

      factory = RGeo::Geographic.spherical_factory(srid: 4326)
      point1 = factory.point(-0.1185926, 51.4656522)
      point2 = factory.point(-0.1185343, 51.4656693)
      point3 = factory.point(-0.1186801, 51.4656266)
      geometry_collection = factory.collection([point1, point2, point3])

      expect {
        described_class.perform_now(planning_application)
      }.to change {
        planning_application.neighbour_boundary_geojson
      }.from(nil).to(geometry_collection)
    end
  end

  context "OS places returns no addresses" do
    it "doesn't fail" do
      stub_request(:get, "https://api.os.uk/search/places/v1/radius?key=testtest&output_srs=EPSG:4258&point=#{planning_application.latitude},#{planning_application.longitude}&radius=50&srs=EPSG:4258")
        .to_return(status: 200, body: "{}", headers: {})

      expect {
        described_class.perform_now(planning_application)
      }.not_to change {
        planning_application.neighbour_boundary_geojson
      }.from(nil)
    end
  end
end
