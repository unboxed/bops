# frozen_string_literal: true

namespace :herb do
  desc "Run herb linter"
  task lint: :environment do
    exit 1 unless system "node_modules/.bin/herb-lint ."
  end

  namespace :lint do
    desc "Run herb linter and apply fixes"
    task fix: :environment do
      exit 1 unless system "node_modules/.bin/herb-lint --fix ."
    end
  end
end
