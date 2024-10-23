# frozen_string_literal: true

module FileDownloaders
  class NoAuthentication < BaseDownloader
    def authenticate(connection)
      # no-op
    end
  end
end
