# frozen_string_literal: true

FactoryBot.define do
  factory :planning_application_constraints_query do
    planning_application

    geojson do
      {"type" => "Feature", "properties" => {}, "geometry" => {"type" => "Polygon", "coordinates" => [[[-0.054597, 51.537331], [-0.054588, 51.537287], [-0.054453, 51.537313], [-0.054597, 51.537331]]]}}
    end
    wkt { "POLYGON ((-0.054597 51.537331, -0.054588 51.537287, -0.054453 51.537313, -0.054597 51.537331))" }
    planx_query { "https://api.editor.planx.uk/gis/opensystemslab?geom=POLYGON+%28%28-0.07629275321961124+51.48596289289142%2C+-0.0763061642646857+51.48591028066045%2C+-0.07555112242699404+51.48584764697301%2C+-0.07554173469544191+51.48590192950712%2C+-0.07629275321961124+51.48596289289142%29%29&analytics=false" }
    planning_data_query { "https://www.planning.data.gov.uk/entity.json?entries=current&geometry=POLYGON+%28%28-0.07629275321961124+51.48596289289142%2C+-0.0763061642646857+51.48591028066045%2C+-0.07555112242699404+51.48584764697301%2C+-0.07554173469544191+51.48590192950712%2C+-0.07629275321961124+51.48596289289142%29%29&geometry_relation=intersects&limit=100&dataset=article-4-direction-area&dataset=central-activities-zone&dataset=listed-building&dataset=listed-building-outline&dataset=locally-listed-building&dataset=park-and-garden&dataset=conservation-area&dataset=area-of-outstanding-natural-beauty&dataset=national-park&dataset=world-heritage-site&dataset=world-heritage-site-buffer-zone&dataset=special-protection-area&dataset=scheduled-monument&dataset=tree&dataset=tree-preservation-order&dataset=tree-preservation-zone&dataset=site-of-special-scientific-interest&dataset=special-area-of-conservation&dataset=ancient-woodland" }
  end
end
