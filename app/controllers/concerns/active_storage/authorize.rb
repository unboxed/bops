# frozen_string_literal: true

module ActiveStorage
  module Authorize
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_user!
    end
  end
end
