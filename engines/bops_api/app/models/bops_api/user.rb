# frozen_string_literal: true

module BopsApi
  class User < ApplicationRecord
    self.table_name = "api_users"

    attribute :file_downloader, FileDownloaders.to_type
    belongs_to :local_authority, optional: true
    has_secure_token :token

    with_options presence: true do
      validates :name, :token
      validates :file_downloader, store_model: true
    end

    class << self
      def authenticate(token)
        find_by(token: token)
      end
    end
  end
end
