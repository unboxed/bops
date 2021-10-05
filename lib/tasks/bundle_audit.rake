# frozen_string_literal: true

desc "Audit bundle for any known vulnerabilities"
task bundle_audit: :environment do
  exit 1 unless system "bundle-audit check --update"
end
