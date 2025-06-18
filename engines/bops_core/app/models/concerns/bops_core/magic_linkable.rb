# frozen_string_literal: true

module BopsCore
  module MagicLinkable
    extend ActiveSupport::Concern
    include GlobalID::Identification

    def sgid(expires_in: 7.days, for: "magic_link")
      to_sgid(expires_in:, for:).to_s
    end
  end
end
