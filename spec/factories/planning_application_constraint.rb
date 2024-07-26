# frozen_string_literal: true

FactoryBot.define do
  factory :planning_application_constraint do
    planning_application
    constraint
    planning_application_constraints_query

    identified_by { "BOPS" }

    trait :with_tree_preservation_zone do
      data {
        [
          {
            "name" => "School Nature Area, Cobourg Road",
            "entity" => 19109825,
            "prefix" => "tree-preservation-zone",
            "dataset" => "tree-preservation-zone",
            "end-date" => "",
            "typology" => "geography",
            "reference" => "",
            "entry-date" => "2021-12-02",
            "start-date" => "1993-01-13",
            "organisation-entity" => "329",
            "tree-preservation-type" => "Woodland",
            "tree-preservation-order" => "228"
          }
        ]
      }
    end

    trait :with_listed_building_and_outline do
      data {
        [
          {
            "name" => "47, COBOURG ROAD",
            "entity" => 31834148,
            "prefix" => "listed-building",
            "dataset" => "listed-building",
            "end-date" => "",
            "typology" => "geography",
            "reference" => "1378486",
            "entry-date" => "2023-05-25",
            "start-date" => "1986-01-24",
            "documentation-url" => "https://historicengland.org.uk/listing/the-list/list-entry/1378486",
            "organisation-entity" => "16",
            "listed-building-grade" => "II"
          },
          {
            "name" => "",
            "entity" => 42102419,
            "prefix" => "listed-building-outline",
            "dataset" => "listed-building-outline",
            "end-date" => "",
            "typology" => "geography",
            "reference" => "470787",
            "entry-date" => "2021-12-08",
            "start-date" => "1986-01-24",
            "documentation-url" => "https://geo.southwark.gov.uk/connect/analyst/Includes/ListedBuildings/SwarkLB201.pdf",
            "organisation-entity" => "329",
            "listed-building-grade" => "II"
          }
        ]
      }
    end
  end
end
