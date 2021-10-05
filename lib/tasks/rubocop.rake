# frozen_string_literal: true

desc "Run the rubocop static code analyzer"
task rubocop: :environment do
  exit 1 unless system "rubocop"
end
