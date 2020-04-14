# frozen_string_literal: true

desc "Run the rubocop static code analyzer"
task rubocop: :environment do
  unless system "rubocop"
    exit 1
  end
end
