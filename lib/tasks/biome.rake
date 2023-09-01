# frozen_string_literal: true

desc "Run biome linter"
task biome: :environment do
  exit 1 unless system "git ls-files -z '*.js' '*.ts' | xargs -0 node_modules/.bin/biome ci"
end
