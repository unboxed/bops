# frozen_string_literal: true

BopsUploads::Engine.routes.draw do
  get "/:key", to: "files#show", as: "file"
end

Rails.application.routes.draw do
  direct :uploaded_file do |blob, options|
    next "" if blob.blank?

    bops_uploads.file_url(blob.key, host: Rails.configuration.uploads_base_url)
  end

  resolve("ActiveStorage::Attachment") { |attachment, options| route_for(:uploaded_file, attachment.blob, options) }
  resolve("ActiveStorage::Blob") { |blob, options| route_for(:uploaded_file, blob, options) }
  resolve("ActiveStorage::Preview") { |preview, options| route_for(:uploaded_file, preview, options) }
  resolve("ActiveStorage::VariantWithRecord") { |variant, options| route_for(:uploaded_file, variant, options) }
  resolve("ActiveStorage::Variant") { |variant, options| route_for(:uploaded_file, variant, options) }
end
