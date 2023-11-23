# frozen_string_literal: true

FactoryBot.define do
  factory :validation_request do
    planning_application { create(:planning_application, :invalidated) }
    user
    request_type { "fee_change" }
    state { "open" }
    reason { "Incorrect fee" }
    post_validation { false }

    trait :fee_change_validation_request do
      request_type { "fee_change" }
      reason { "Incorrect fee" }
      specific_attributes do
        {suggestion: "You need to pay a different fee"}
      end
    end

    trait :other_change_validation_request do
      request_type { "other" }
      state { "open" }
      reason { "Something else was wrong" }
      specific_attributes do
        {summary: "You need to pay a different fee"}
      end
    end

    trait :additional_document_validation_request do
      request_type { "additional_document" }
      reason { "Missing floor plan" }
      specific_attributes do
        {
          document_request_type: "Floor plan"
        }
      end
    end

    trait :additional_document_validation_request_with_documents do
      request_type { "additional_document" }
      reason { "Missing floor plan" }
      specific_attributes do
        {
          document_request_type: "Floor plan"
        }
      end

      before(:create) do |request|
        document = create(
          :document,
          planning_application: request.planning_application
        )

        request.documents << document
      end
    end

    trait :red_line_boundary_change_validation_request do
      specific_attributes do
        new_geojson do
          '{
            "type": "Feature",
            "geometry": {
              "type": "Polygon",
              "coordinates": [
                [
                  [-0.07716178894042969, 51.50094238217541],
                  [-0.07645905017852783, 51.50053497847238],
                  [-0.07615327835083008, 51.50115276135022],
                  [-0.07716178894042969, 51.50094238217541]
                ]
              ]
            }
          }'
        end
      end
      reason { "Boundary incorrect" }
    end

    trait :replacement_document_validation_request do
      old_document factory: :document
      reason { "Document is invalid" }
      request_type { "replacement_document" }
    end

    trait :description_change_validation_request do
      reason { "Description is incorrect" }
      specific_attributes do
        {
          proposed_description: "New description"
        }
      end
      request_type { "description_change" }
    end

    trait :pending do
      planning_application { create(:planning_application, :not_started) }

      state { "pending" }
    end

    trait :open do
      state { "open" }
    end

    trait :closed do
      state { "closed" }
      applicant_response { "Some response" }
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
