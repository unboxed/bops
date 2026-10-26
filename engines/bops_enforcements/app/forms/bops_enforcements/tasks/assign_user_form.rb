# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class AssignUserForm < Form
      attribute :user_id

      after_initialize do
        @users = case_record.local_authority.users.non_administrator
      end

      attr_reader :users

      def redirect_url
        enforcement_path(enforcement)
      end

      private

      def save_and_complete
        case_record.update!(user_id:)
      end
    end
  end
end
