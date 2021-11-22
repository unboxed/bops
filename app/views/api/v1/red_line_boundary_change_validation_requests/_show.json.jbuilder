# frozen_string_literal: true

json.extract! red_line_boundary_change_validation_request,
              :id,
              :state,
              :response_due,
              :new_geojson,
              :reason,
              :rejection_reason,
              :approved,
              :days_until_response_due,
              :cancel_reason,
              :cancelled_at
