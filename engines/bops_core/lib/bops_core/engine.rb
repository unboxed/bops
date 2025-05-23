# frozen_string_literal: true

require "govuk/components"

module BopsCore
  class Engine < ::Rails::Engine
    isolate_namespace BopsCore

    initializer "bops_core.rescue_responses" do
      config.after_initialize do
        ActionDispatch::ExceptionWrapper.rescue_responses.merge! \
          "BopsCore::Errors::ClientError" => :bad_request,
          "BopsCore::Errors::BadRequestError" => :bad_request,
          "BopsCore::Errors::UnauthorizedError" => :unauthorized,
          "BopsCore::Errors::ForbiddenError" => :forbidden,
          "BopsCore::Errors::NotFoundError" => :not_found,
          "BopsCore::Errors::NotAcceptableError" => :not_acceptable,
          "BopsCore::Errors::UnprocessableContentError" => :unprocessable_content,
          "BopsCore::Errors::ServerError" => :internal_server_error,
          "BopsCore::Errors::InternalServerError" => :internal_server_error,
          "BopsCore::Errors::ServiceUnavailableError" => :service_unavailable
      end
    end
  end
end
