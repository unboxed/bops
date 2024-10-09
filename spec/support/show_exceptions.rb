# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:each, type: :request) do |example|
    if example.metadata.key?(:show_exceptions)
      begin
        env_config = Rails.application.env_config
        show_exceptions = env_config["action_dispatch.show_exceptions"]
        env_config["action_dispatch.show_exceptions"] = example.metadata[:show_exceptions] ? :all : :none

        example.run
      ensure
        env_config["action_dispatch.show_exceptions"] = show_exceptions
      end
    else
      example.run
    end
  end
end
