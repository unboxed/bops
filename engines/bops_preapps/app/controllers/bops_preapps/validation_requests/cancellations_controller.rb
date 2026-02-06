# frozen_string_literal: true

module BopsPreapps
  module ValidationRequests
    class CancellationsController < AuthenticationController
      include BopsCore::ValidationRequests::CancellationsController
    end
  end
end
