# frozen_string_literal: true

module BopsUploads
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController

    with_options to: :BopsUploads do
      delegate :key_pair_id, :private_key, :cookie_signer
    end

    before_action :require_local_authority!
    before_action :set_service

    private

    def set_service
      @service = ActiveStorage::Blob.service
    end

    def set_blob
      @blob = ActiveStorage::Blob.find_by!(key: params[:key])
    end
  end
end
