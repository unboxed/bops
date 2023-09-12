# frozen_string_literal: true

Grover.configure do |config|
  if Gem::Platform.local.os != "darwin"
    config.options = {
      executable_path: "/usr/bin/chromium"
    }
  end
end
