# frozen_string_literal: true

module FileDownloaders
  class HeaderAuthentication < BaseDownloader
    attribute :key, :string
    attribute :value, :string

    with_options presence: true do
      validates :key, :value
    end

    def authenticate(connection)
      connection.headers[key] = value
    end
  end
end
