# frozen_string_literal: true

BopsUploads::Engine.routes.draw do
  extend BopsCore::Routing

  local_authority_subdomain do
    get "/blobs/:key", to: "blobs#show", as: "blob"
    get "/files/:key", to: "files#show", as: "file"

    post "/uploads", to: "uploads#create", as: "uploads"
  end
end

Rails.application.routes.draw do
  extend BopsCore::Routing

  namespace :bops_uploads, path: nil do
    local_authority_subdomain do
      get "/files/:key", to: "files#show", as: "file"

      unless Rails.env.production?
        scope "/disk" do
          get "/:encoded_key/*filename", to: "disk#show", as: "disk_service"
          put "/:encoded_token", to: "disk#update", as: "update_disk_service"
        end
      end
    end
  end

  direct :uploaded_file do |blob, options|
    next "" if blob.blank?

    route_for(:bops_uploads_file, blob.key, options)
  end

  unless Rails.env.production?
    direct :rails_disk_service do |encoded_key, filename, options|
      route_for(:bops_uploads_disk_service, encoded_key, filename, (options || {}).merge(only_path: true))
    end

    direct :update_rails_disk_service do |encoded_token, options|
      route_for(:bops_uploads_update_disk_service, encoded_token, (options || {}).merge(only_path: true))
    end
  end

  resolve("ActiveStorage::Attachment") { |attachment, options| route_for(:uploaded_file, attachment.blob, options) }
  resolve("ActiveStorage::Blob") { |blob, options| route_for(:uploaded_file, blob, options) }
  resolve("ActiveStorage::Preview") { |preview, options| route_for(:uploaded_file, preview, options) }
  resolve("ActiveStorage::VariantWithRecord") { |variant, options| route_for(:uploaded_file, variant.blob, options) }
  resolve("ActiveStorage::Variant") { |variant, options| route_for(:uploaded_file, variant.blob, options) }
  resolve("ActionText::Attachment") { |attachment, options| route_for(:uploaded_file, attachment.attachable, options) }
  resolve("Document") { |document, options| route_for(:uploaded_file, document.file, options) }
end
