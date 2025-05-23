# frozen_string_literal: true

module BopsCore
  module Errors
    class Error < ::StandardError; end

    # 4xx errors
    class ClientError < Error; end
    class BadRequestError < ClientError; end
    class UnauthorizedError < ClientError; end
    class ForbiddenError < ClientError; end
    class NotFoundError < ClientError; end
    class NotAcceptableError < ClientError; end
    class UnprocessableContentError < ClientError; end

    # 5xx errors
    class ServerError < Error; end
    class InternalServerError < ServerError; end
    class ServiceUnavailableError < ServerError; end

    class << self
      # rubocop:disable Rails/ApplicationController
      def precompile(public_path = Rails.public_path)
        controller_class = Class.new(ActionController::Base) do
          def url_options
            {}
          end
        end

        context_class = Class.new(ActionView::Base.with_empty_template_cache) do
          include Rails.application.routes.url_helpers
        end

        lookup_context = ActionView::LookupContext.new("engines/bops_core/app/views")
        ActionView::Base.annotate_rendered_view_with_filenames = false

        %w[400 401 403 404 406 422 500 503].each do |status|
          context = context_class.new(lookup_context, {status: status}, controller_class.new)

          public_path.join("#{status}.html").open("w", binmode: true) do |f|
            f.write context.render(template: "bops_core/errors/#{status}", layout: "bops_core/errors/layout")
          end
        end

        context = context_class.new(lookup_context, {}, controller_class.new)

        public_path.join("error.css").open("w", binmode: true) do |f|
          f.write context.render(template: "bops_core/errors/error", layout: false)
        end

        fonts_dir = public_path.join("fonts")
        FileUtils.mkdir_p(fonts_dir)

        Dir[Rails.root.join("app/assets/fonts/*.woff2")].each do |font|
          FileUtils.cp(font, fonts_dir.join(File.basename(font)))
        end
      end
      # rubocop:enable Rails/ApplicationController

      def clobber(public_path = Rails.public_path)
        %w[400 401 403 404 406 422 500 503].each do |status|
          html_file = public_path.join("#{status}.html")
          File.unlink(html_file) if File.exist?(html_file)
        end

        css_file = public_path.join("error.css")
        File.unlink(css_file) if File.exist?(css_file)

        fonts_dir = public_path.join("fonts")
        FileUtils.rm_rf(fonts_dir)
      end
    end
  end
end
