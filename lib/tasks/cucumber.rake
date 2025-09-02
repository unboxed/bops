# frozen_string_literal: true

desc "Run cucumber"
task cucumber: :environment do
  cmd = "cucumber"
  cmd << " --color" if ENV["CI"].present?
  exit 1 unless cmd
end
