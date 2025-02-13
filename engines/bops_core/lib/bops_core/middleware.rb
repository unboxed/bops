# frozen_string_literal: true

module BopsCore
  module Middleware
    autoload :LocalAuthority, "bops_core/middleware/local_authority"
    autoload :User, "bops_core/middleware/user"
  end
end
