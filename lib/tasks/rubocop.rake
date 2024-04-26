# frozen_string_literal: true

desc "Run the rubocop static code analyzer"
task rubocop: :environment do
  exit 1 unless system "rubocop"
end

namespace :rubocop do
  desc "Run the rubocop static code analyzer and apply fixes"
  task fix: :environment do
    exit 1 unless system "rubocop --autocorrect-all"
  end
end
