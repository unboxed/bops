# frozen_string_literal: true

RSpec.configure do |config|
  # Sidekiq logs on connecting to redis so redirect STDOUT whilst it
  # connects to prevent an ugly message in the middle of our green dots
  config.before(:suite) do
    stdout, $stdout = $stdout, StringIO.new
    Sidekiq::Stats.new
  ensure
    $stdout = stdout
  end
end
