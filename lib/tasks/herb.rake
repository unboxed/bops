# frozen_string_literal: true

namespace :herb do
  desc "Run herb linter"
  task lint: :environment do
    exit 1 unless system "node_modules/.bin/herb-lint app engines/*/app"
  end
end
