# frozen_string_literal: true

Rails.application.config.to_prepare do
  ActiveStorage::DiskController.include ActiveStorage::Authorize
  ActiveStorage::Blobs::RedirectController.include ActiveStorage::Authorize
  ActiveStorage::Blobs::ProxyController.include ActiveStorage::Authorize
  ActiveStorage::Representations::RedirectController.include ActiveStorage::Authorize
  ActiveStorage::Representations::ProxyController.include ActiveStorage::Authorize
end

ActiveSupport.on_load(:active_storage_blob) do
  module ActiveStorage
    class NotPermittedContentType < StandardError; end

    class Blob < ActiveStorage::Record
      before_create :content_type_permitted

      def content_type_permitted
        return if Document::PERMITTED_CONTENT_TYPES.include? file.blob.content_type

        raise NotPermittedContentType, "#{file.blob.content_type} is not permitted"
      end
    end
  end
end
