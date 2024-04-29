# frozen_string_literal: true

desc "Ensure language versions match"
task language_versions: :environment do
  exit 1 unless system "bin/verify-language-versions.sh"
end
