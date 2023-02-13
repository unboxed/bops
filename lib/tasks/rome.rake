# frozen_string_literal: true

desc "Run rome linter"
task rome: :environment do
  exit 1 unless system "git ls-files -z '*.js' '*.ts' | xargs -0 node_modules/rome/bin/rome ci"
end
