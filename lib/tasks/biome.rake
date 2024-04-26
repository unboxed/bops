# frozen_string_literal: true

desc "Run biome linter"
task biome: :environment do
  exit 1 unless system "git ls-files -z '*.js' '*.ts' | xargs -0 node_modules/.bin/biome ci"
end

namespace :biome do
  desc "Run biome linter and apply fixes"
  task fix: :environment do
    exit 1 unless system "git ls-files -z '*.js' '*.ts' | xargs -0 node_modules/.bin/biome format --write"
    exit 1 unless system "git ls-files -z '*.js' '*.ts' | xargs -0 node_modules/.bin/biome check --apply-unsafe"
  end
end
