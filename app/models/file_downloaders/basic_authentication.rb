# frozen_string_literal: true

module FileDownloaders
  class BasicAuthentication < BaseDownloader
    attribute :username, :string
    attribute :password, :string

    with_options presence: true do
      validates :username, :password
    end

    def authenticate(connection)
      connection.request :basic_auth, username, password
    end
  end
end
