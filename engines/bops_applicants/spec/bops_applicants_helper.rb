# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.before type: :request do
    host!("planx.bops-applicants.services")
  end
end
