# frozen_string_literal: true

module ActiveStorage
  module SetDiskBlob
    extend ActiveSupport::Concern

    included do
      before_action :verify_request
      before_action :set_disk_blob
    end

    private

    def set_disk_blob
      @blob ||= begin
        ActiveStorage::Blob.find_by(key: decrypted_hash[:key])
      rescue StandardError
        head :not_found
      end
    end

    def encrypted_hash
      params[:encoded_key] || params[:encoded_token]
    end

    def decrypted_hash
      # rubocop:disable Security/MarshalLoad
      Marshal.load(Base64.decode64(json_parsed_hash))
      # rubocop:enable Security/MarshalLoad
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
  end
end
