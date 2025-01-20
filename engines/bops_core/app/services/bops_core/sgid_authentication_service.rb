# frozen_string_literal: true

module BopsCore
  class SgidAuthenticationService
    attr_reader :sgid, :purpose

    def initialize(sgid, purpose: "magic_link")
      @sgid = sgid
      @purpose = purpose
    end

    def locate_resource
      GlobalID::Locator.locate_signed(sgid, for: purpose)
    end

    def expired_resource
      gid = parse_global_id
      return nil unless gid

      gid.model_class.find_by(id: gid.model_id)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    private

    def parse_global_id
      encoded, = sgid.split("--")
      decoded = Base64.urlsafe_decode64(CGI.unescape(encoded))
      parsed = JSON.parse(decoded)

      return nil unless parsed.dig("_rails", "pur") == purpose

      GlobalID.parse(parsed.dig("_rails", "data"))
    rescue JSON::ParserError, TypeError, ArgumentError
      nil
    end
  end
end
