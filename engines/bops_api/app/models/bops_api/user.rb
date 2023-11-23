# frozen_string_literal: true

module BopsApi
  class User < ApplicationRecord
    self.table_name = "api_users"

    belongs_to :local_authority, optional: true

    class << self
      def authenticate(token)
        find_by(token: token)
      end
    end
  end
end
