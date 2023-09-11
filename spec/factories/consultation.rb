# frozen_string_literal: true

FactoryBot.define do
  factory :consultation do
    planning_application

    trait :started do
      start_date { 2.days.ago }
      end_date { 2.days.ago + 21.days }
    end

    trait :with_polygon_search do
      polygon_search do
        factory = RGeo::Geographic.spherical_factory(srid: 4326)
        polygon = factory.polygon(
          factory.linear_ring([
                                factory.point(-0.07739927369747812, 51.501345554406896),
                                factory.point(-0.0778893839394212, 51.501002280754676),
                                factory.point(-0.07690508968054104, 51.50102474569704),
                                factory.point(-0.07676672973966252, 51.50128963605792),
                                factory.point(-0.07739927369747812, 51.501345554406896)
                              ])
        )
        geometry_collection = factory.collection([polygon])
        geometry_collection
      end
    end
  end
end
