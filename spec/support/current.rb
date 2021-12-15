# frozen_string_literal: true

RSpec.configure do |config|
  config.after do
    Current.user = nil
    Current.api_user = nil
  end
end
