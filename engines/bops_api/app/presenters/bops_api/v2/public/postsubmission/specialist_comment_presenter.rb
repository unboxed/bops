# frozen_string_literal: true

module BopsApi
  module V2
    module Public
      module Postsubmission
        class SpecialistCommentPresenter
          extend Forwardable
          def_delegators :@consultee, :id, :organisation, :role, :email_sent_at, :planning_application_constraints

          def initialize(consultee, responses)
            @consultee = consultee
            @responses = responses
          end

          def reason
            active_constraints = planning_application_constraints.active
            reason_type_code = active_constraints.first&.constraint&.type_code
            reason_type_code.present? ? "Constraint" : "Other"
          end

          def active_constraints
            planning_application_constraints.active
          end

          def comments
            @responses
          end
        end
      end
    end
  end
end
