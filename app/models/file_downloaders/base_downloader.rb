# frozen_string_literal: true

require "faraday"

module FileDownloaders
  class BaseDownloader
    include StoreModel::Model

    attribute :type, :string
    attribute :open_timeout, :integer, default: 5
    attribute :read_timeout, :integer, default: 5

    with_options presence: true do
      validates :open_timeout, :read_timeout
      validates :type, strict: true
    end

    def initialize(*)
      super

      # Ensure that the correct type is stored
      self.type = self.class.name.demodulize
    end

    def authenticate(request)
      raise NotImplementedError, "Subclasses of BaseDownloader need to implement #authenticate"
    end

    def get(url)
      Tempfile.new("bops-document-download", encoding: "ascii-8bit").tap do |file|
        uri = URI.parse(url)

        connection = Faraday.new(uri.origin) do |faraday|
          authenticate(faraday)

          faraday.response :raise_error
        end

        connection.get(uri.request_uri) do |request|
          request.options.open_timeout = open_timeout
          request.options.read_timeout = read_timeout

          request.options.on_data = ->(chunk, size) {
            file.write(chunk)
          }
        end

        file.rewind
      ensure
        file.close
      end
    end
  end
end
