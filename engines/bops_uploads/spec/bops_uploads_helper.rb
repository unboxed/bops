# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.before type: :request do
    host!("uploads.bops.services")
  end
end
