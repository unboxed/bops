# frozen_string_literal: true

require "aws-sdk-cloudfront"

module BopsUploads
  class Engine < ::Rails::Engine
    isolate_namespace BopsUploads

    initializer "bops_uploads.cookie_signer" do
      config.after_initialize do
        key_pair_id = ENV.fetch("UPLOADS_PUBLIC_KEY_ID") do
          SecureRandom.alphanumeric(14).upcase
        end

        private_key = ENV.fetch("UPLOADS_PRIVATE_KEY") do
          OpenSSL::PKey::RSA.generate(2048).to_pem
        end

        cookie_signer = Aws::CloudFront::CookieSigner.new(key_pair_id:, private_key:)

        BopsUploads.key_pair_id = key_pair_id
        BopsUploads.private_key = OpenSSL::PKey::RSA.new(private_key)
        BopsUploads.cookie_signer = cookie_signer
      end
    end

    initializer "bops_uploads.parent_record" do
      ActiveSupport.on_load(:active_storage_blob) do
        def parent_record(record = attachments.sole.record)
          case record
          when ActiveStorage::Blob
            parent_record(record.attachments.sole.record)
          when ActiveStorage::VariantRecord
            parent_record(record.blob.attachments.sole.record)
          else
            record
          end
        end

        alias_method :document, :parent_record
      end
    end
  end
end
