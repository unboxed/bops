# frozen_string_literal: true

desc "Run cucumber"
task cucumber: :environment do
  exit 1 unless system "cucumber"
end
