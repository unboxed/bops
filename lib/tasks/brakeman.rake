# frozen_string_literal: true

desc "Run brakeman checks and exit with an error code if there are any issues"
task brakeman: :environment do
  exit 1 unless system "brakeman -z --no-pager"
end
