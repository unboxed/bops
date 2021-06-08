FactoryBot.define do
  factory :red_line_boundary_change_request do
    planning_application
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
        }'
    end
    reason { "Boundary incorrect" }
    approved { nil }
  end
end
