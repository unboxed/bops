FactoryBot.define do
  factory :red_line_boundary_change_request do
    planning_application { nil }
    user { nil }
    state { "MyString" }
    new_geojson { "MyString" }
    reason { "MyString" }
    rejection_reason { "MyString" }
  end
end
