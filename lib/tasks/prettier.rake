# frozen_string_literal: true

desc "Run prettier linter"
task prettier: :environment do
  exit 1 unless system "git ls-files -z '*.scss' | xargs -0 node_modules/.bin/prettier --check"
end

namespace :prettier do
  desc "Run prettier linter and apply fixes"
  task fix: :environment do
    exit 1 unless system "git ls-files -z '*.scss' | xargs -0 node_modules/.bin/prettier --write"
  end
end
