# frozen_string_literal: true

module ActiveStorage
  module SetDiskBlob
    extend ActiveSupport::Concern

    included do
      before_action :verify_request
      before_action :set_disk_blob, if: :not_from_bops?
    end

    private

    def set_disk_blob
      @blob ||= begin # rubocop:disable Naming/MemoizedInstanceVariableName
        ActiveStorage::Blob.find_by(key: decrypted_hash[:key])
      rescue
        head :not_found
      end
    end

    def encrypted_hash
      params[:encoded_key] || params[:encoded_token]
    end

    def decrypted_hash
      Marshal.load(Base64.decode64(json_parsed_hash)) # rubocop:disable Security/MarshalLoad
    end

    def decoded_hash
      Base64.decode64(encrypted_hash)
    end

    def json_parsed_hash
      JSON.parse(decoded_hash).dig("_rails", "message")
    end

    def verify_request
      ActiveStorage.verifier.valid_message?(encrypted_hash)
    end

    def not_from_bops?
      request.referer.include?("bops-care") || request.referer.include?("bops-applicants")
    end
  end
end
