# frozen_string_literal: true

module FileDownloaders
  class BearerAuthentication < BaseDownloader
    attribute :token, :string

    with_options presence: true do
      validates :token
    end

    def authenticate(connection)
      connection.request :authorization, "Bearer", token
    end
  end
end
