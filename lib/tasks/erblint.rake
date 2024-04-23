# frozen_string_literal: true

desc "Run erblint linter"
task erblint: :environment do
  exit 1 unless system "git ls-files -z '*.erb'| xargs -0 erblint"
end
