# frozen_string_literal: true

module BopsUploads
  class RedirectsController < ApplicationController
    include ActiveStorage::SetBlob
    include ActiveStorage::SetCurrent

    before_action :authenticate_user!

    rescue_from ActiveSupport::MessageVerifier::InvalidSignature do
      head :not_found
    end

    def show
      expires_in ActiveStorage.service_urls_expire_in
      redirect_to @blob.url(disposition: params[:disposition]), allow_other_host: true
    end
  end
end
