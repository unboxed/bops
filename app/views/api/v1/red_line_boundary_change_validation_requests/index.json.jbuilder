# frozen_string_literal: true

json.data @red_line_boundary_change_validation_requests.each do |red_line_boundary_change_validation_request|
  json.partial! "show", red_line_boundary_change_validation_request: red_line_boundary_change_validation_request
end
