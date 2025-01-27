# frozen_string_literal: true

BopsUploads::Engine.routes.draw do
  extend BopsCore::Routing

  local_authority_subdomain do
    get "/blobs/:key", to: "blobs#show", as: "blob"
    get "/files/:key", to: "files#show", as: "file"
  end

  uploads_subdomain do
    get "/:key", to: "blobs#show", as: "upload"
  end
end

Rails.application.routes.draw do
  extend BopsCore::Routing

  namespace :bops_uploads, path: nil do
    local_authority_subdomain do
      get "/files/:key", to: "files#show", as: "file"
    end

    uploads_subdomain do
      get "/:key", to: "blobs#show", as: "upload"
    end
  end

  direct :uploaded_file do |blob, options|
    next "" if blob.blank?

    if Rails.configuration.use_signed_cookies
      route_for(:bops_uploads_file, blob.key, options)
    else
      route_for(:bops_uploads_upload, blob.key, options.merge(host: Rails.configuration.uploads_base_url))
    end
  end

  resolve("ActiveStorage::Attachment") { |attachment, options| route_for(:uploaded_file, attachment.blob, options) }
  resolve("ActiveStorage::Blob") { |blob, options| route_for(:uploaded_file, blob, options) }
  resolve("ActiveStorage::Preview") { |preview, options| route_for(:uploaded_file, preview, options) }
  resolve("ActiveStorage::VariantWithRecord") { |variant, options| route_for(:uploaded_file, variant, options) }
  resolve("ActiveStorage::Variant") { |variant, options| route_for(:uploaded_file, variant, options) }
  resolve("Document") { |document, options| route_for(:uploaded_file, document.file, options) }
end
