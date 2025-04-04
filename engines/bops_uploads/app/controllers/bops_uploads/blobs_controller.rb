# frozen_string_literal: true

module BopsUploads
  class BlobsController < ApplicationController
    before_action :set_blob

    def show
      serve_file(blob_path, content_type:, disposition:)
    rescue Errno::ENOENT
      head :not_found
    end

    private

    def blob_path
      @service.path_for(@blob.key)
    end

    def forcibly_serve_as_binary?
      ActiveStorage.content_types_to_serve_as_binary.include?(@blob.content_type)
    end

    def allowed_inline?
      ActiveStorage.content_types_allowed_inline.include?(@blob.content_type)
    end

    def content_type
      forcibly_serve_as_binary? ? ActiveStorage.binary_content_type : @blob.content_type
    end

    def disposition
      if forcibly_serve_as_binary? || !allowed_inline?
        :attachment
      else
        :inline
      end
    end

    def serve_file(path, content_type:, disposition:)
      ::Rack::Files.new(nil).serving(request, path).tap do |(status, headers, body)|
        self.status = status
        self.response_body = body

        headers.each do |name, value|
          response.headers[name] = value
        end

        response.headers.except!("X-Cascade", "x-cascade") if status == 416
        response.headers["Content-Type"] = content_type || DEFAULT_SEND_FILE_TYPE
        response.headers["Content-Disposition"] = disposition || DEFAULT_SEND_FILE_DISPOSITION
      end
    end
  end
end
