# frozen_string_literal: true

module BopsCore
  class PublicExceptions
    CONTENT_TYPE = Rack::CONTENT_TYPE
    CONTENT_LENGTH = Rack::CONTENT_LENGTH
    STATUS_CODES = Rack::Utils::HTTP_STATUS_CODES
    X_CASCADE = "x-cascade"

    attr_accessor :public_path

    def initialize(public_path)
      @public_path = public_path
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      status = request.path_info[1..].to_i
      content_type = request.formats.first

      body = {
        "status" => status,
        "error" => error(status),
        "request-id" => request.uuid,
        "timestamp" => Time.now.getutc.iso8601
      }

      render(status, content_type, body)
    end

    private

    def error(status)
      STATUS_CODES.fetch(status, STATUS_CODES[500])
    end

    def render(status, content_type, body)
      format = :"to_#{content_type.to_sym}" if content_type

      if format && body.respond_to?(format)
        render_format(status, content_type, body.public_send(format))
      else
        render_html(status, body)
      end
    end

    def render_format(status, content_type, body)
      [status, headers(content_type, body), [body]]
    end

    def headers(content_type, body)
      {
        CONTENT_TYPE => "#{content_type}; charset=utf-8",
        CONTENT_LENGTH => body.bytesize.to_s
      }
    end

    def render_html(status, body)
      path = "#{public_path}/#{status}.#{I18n.locale}.html"
      path = "#{public_path}/#{status}.html" unless (found = File.exist?(path))

      if found || File.exist?(path)
        html = File.read(path)

        %w[request-id timestamp].each do |item|
          html.gsub!(
            "<!-- #{item} -->",
            "<strong>#{item}:</strong> #{body[item]}"
          )
        end

        render_format(status, "text/html", html)
      else
        [404, {X_CASCADE => "pass"}, []]
      end
    end
  end
end
