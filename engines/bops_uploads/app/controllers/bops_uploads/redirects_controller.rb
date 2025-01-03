# frozen_string_literal: true

module BopsUploads
  class RedirectsController < ApplicationController
    def show
      redirect_to redirect_url, allow_other_host: true
    end

    private

    def redirect_url
      file_url(params[:key], host: uploads_base_url)
    end

    def uploads_base_url
      Rails.configuration.uploads_base_url
    end
  end
end
