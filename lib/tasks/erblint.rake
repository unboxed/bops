# frozen_string_literal: true

desc "Run erb_lint linter"
task erb_lint: :environment do
  exit 1 unless system "git ls-files -z '*.erb'| xargs -0 erb_lint"
end

namespace :erb_lint do
  desc "Run erb_lint linter and apply fixes"
  task fix: :environment do
    exit 1 unless system "git ls-files -z '*.erb'| xargs -0 erb_lint -a"
  end
end
