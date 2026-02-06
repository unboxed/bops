# frozen_string_literal: true

module ValidationRequests
  class CancellationsController < AuthenticationController
    include BopsCore::ValidationRequests::CancellationsController
  end
end
