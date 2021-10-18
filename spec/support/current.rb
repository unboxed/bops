# frozen_string_literal: true

RSpec.configure do |config|
  config.after do
    Current.user = nil
  end
end
