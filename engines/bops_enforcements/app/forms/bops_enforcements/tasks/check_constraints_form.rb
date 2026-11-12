# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class CheckConstraintsForm < Form
      attribute :details, :string

      after_initialize do
        @constraints = enforcement.constraints
      end
      attr_reader :constraints

      private

      def save_and_complete
        super do
        end
      end
    end
  end
end
