# frozen_string_literal: true

module Bops
  class ErrorsApplication < ActionDispatch::PublicExceptions
    private

    STATUSES = {
      404 => :not_found,
      500 => :internal_server_error
    }

    def render(status, content_type, body)
      status_name = STATUSES[status]
      response_body = ErrorsController.render status_name, layout: nil
      [status, {Rack::CONTENT_TYPE => "#{content_type}; charset=#{ActionDispatch::Response.default_charset}",
                Rack::CONTENT_LENGTH => response_body.bytesize.to_s}, [response_body]]
    rescue
      super
    end
  end
end
