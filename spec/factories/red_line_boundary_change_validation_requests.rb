# frozen_string_literal: true

FactoryBot.define do
  factory :red_line_boundary_change_validation_request do
    planning_application { create :planning_application, :invalidated }
    user
    state { "open" }
    new_geojson do
      '{
        "type": "Feature",
        "geometry": {
            "type": "Polygon",
            "coordinates": [
                [
                    [
                        -0.07716178894042969,
                        51.50094238217541
                    ],
                    [
                        -0.07645905017852783,
                        51.50053497847238
                    ],
                    [
                        -0.07615327835083008,
                        51.50115276135022
                    ],
                    [
                        -0.07716178894042969,
                        51.50094238217541
                    ]
                ]
            ]
        }'.to_json
    end
    reason { "Boundary incorrect" }
    approved { nil }
    post_validation { false }

    trait :pending do
      state { "pending" }
    end

    trait :open do
      state { "open" }
    end

    trait :closed do
      state { "closed" }
    end

    trait :cancelled do
      state { "cancelled" }
      cancel_reason { "Made by mistake!" }
      cancelled_at { Time.current }
    end

    trait :post_validation do
      post_validation { true }
    end
  end
end
