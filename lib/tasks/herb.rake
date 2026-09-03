# frozen_string_literal: true

namespace :herb do
  desc "Run herb linter"
  task lint: :environment do
    exit 1 unless system "node_modules/.bin/herb-lint ."
    exit 1 unless system "node_modules/.bin/herb-format --check ."
  end

  namespace :lint do
    desc "Run herb linter and apply fixes"
    task fix: :environment do
      exit 1 unless system "node_modules/.bin/herb-lint --fix ."
      exit 1 unless system "node_modules/.bin/herb-format ."
    end
  end
end
