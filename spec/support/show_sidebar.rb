# frozen_string_literal: true

RSpec.configure do |config|
  config.around type: :system do |example|
    if example.metadata.key?(:show_sidebar)
      begin
        existing_value = Rails.configuration.use_new_sidebar_layout
        Rails.configuration.use_new_sidebar_layout = example.metadata[:show_sidebar]

        example.run
      ensure
        Rails.configuration.use_new_sidebar_layout = existing_value
      end
    end
  end
end
